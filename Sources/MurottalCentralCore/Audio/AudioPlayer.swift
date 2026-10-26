import AppKit
import AVFoundation
import Foundation
import MediaPlayer
import Observation

/// Pemutar audio berbasis `AVPlayer` dengan dukungan queue, resume posisi,
/// kecepatan putar, repeat, shuffle, serta integrasi Now Playing / media keys.
@MainActor
@Observable
public final class AudioPlayer {

    public enum RepeatMode: String, CaseIterable, Sendable {
        case off, all, one

        public var symbolName: String {
            switch self {
            case .off, .all: return "repeat"
            case .one: return "repeat.1"
            }
        }
    }

    /// Mode sleep timer.
    public enum SleepTimerMode: Equatable, Sendable {
        case off
        /// Berhenti setelah durasi tertentu (detik).
        case duration(TimeInterval)
        /// Berhenti di akhir trek yang sedang diputar.
        case endOfTrack

        public var isActive: Bool { self != .off }
    }

    /// Pilihan durasi sleep timer (menit) yang ditawarkan di UI.
    public static let sleepTimerPresets: [Int] = [5, 10, 15, 30, 45, 60]

    // MARK: State yang diamati UI

    public private(set) var queue: [AudioTrack] = []
    public private(set) var index: Int = 0
    public private(set) var isPlaying = false
    public private(set) var currentTime: Double = 0
    public private(set) var duration: Double = 0
    public private(set) var isBuffering = false

    public private(set) var sleepTimerMode: SleepTimerMode = .off
    /// Sisa waktu sleep timer (detik) bila memakai mode `.duration`.
    public private(set) var sleepTimerRemaining: TimeInterval?

    public var repeatMode: RepeatMode = .off
    public var isShuffled = false
    public var rate: Float = 1.0 {
        didSet {
            player.rate = isPlaying ? rate : 0
            refreshNowPlaying()
        }
    }

    public var current: AudioTrack? {
        guard queue.indices.contains(index) else { return nil }
        return queue[index]
    }

    public var hasNext: Bool {
        index + 1 < queue.count || repeatMode == .all
    }

    public var hasPrevious: Bool {
        index > 0 || repeatMode == .all
    }

    /// Resolver opsional untuk memutar berkas lokal (hasil unduhan).
    public var localURLResolver: (@MainActor (AudioTrack) -> URL?)?

    // MARK: Privat

    private let player = AVPlayer()
    private var timeObserver: Any?
    private var endObserver: NSObjectProtocol?
    private let defaults: UserDefaults
    private let positionKeyPrefix = "murottal.position."

    private var nowPlayingArtwork: MPMediaItemArtwork?
    private var artworkTask: Task<Void, Never>?
    private var lastNowPlayingRefresh: Date = .distantPast
    private var remoteCommandsConfigured = false
    private var sleepTask: Task<Void, Never>?

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        player.actionAtItemEnd = .pause
        installTimeObserver()
        configureRemoteCommands()
    }

    deinit {
        // `AVPlayer` membersihkan observer-nya sendiri saat dilepas. Karena
        // `AudioPlayer` hidup selama aplikasi berjalan, pembersihan eksplisit
        // tidak diperlukan di sini.
    }

    // MARK: Kontrol

    public func play(_ tracks: [AudioTrack], startingAt startIndex: Int = 0) {
        guard !tracks.isEmpty, tracks.indices.contains(startIndex) else { return }
        queue = tracks
        index = startIndex
        loadCurrent(autoPlay: true)
    }

    public func togglePlayPause() {
        if isPlaying { pause() } else { resume() }
    }

    public func resume() {
        guard current != nil else { return }
        player.play()
        player.rate = rate
        isPlaying = true
        refreshNowPlaying()
    }

    public func pause() {
        guard current != nil else { return }
        player.pause()
        isPlaying = false
        savePosition()
        refreshNowPlaying()
    }

    public func next() {
        guard !queue.isEmpty else { return }
        if index + 1 < queue.count {
            index += 1
        } else if repeatMode == .all {
            index = 0
        } else {
            pause()
            return
        }
        loadCurrent(autoPlay: true)
    }

    public func previous() {
        guard !queue.isEmpty else { return }
        // Jika sudah lewat 3 detik, ulangi trek ini.
        if currentTime > 3 {
            seek(to: 0)
            return
        }
        if index > 0 {
            index -= 1
        } else if repeatMode == .all {
            index = queue.count - 1
        } else {
            seek(to: 0)
            return
        }
        loadCurrent(autoPlay: true)
    }

    public func seek(to seconds: Double) {
        let clamped = max(0, min(seconds, duration > 0 ? duration : seconds))
        player.seek(to: CMTime(seconds: clamped, preferredTimescale: 600))
        currentTime = clamped
        refreshNowPlaying()
    }

    public func stop() {
        player.pause()
        player.replaceCurrentItem(with: nil)
        isPlaying = false
        queue = []
        index = 0
        currentTime = 0
        duration = 0
        cancelSleepTimer()
        refreshNowPlaying()
    }

    public func toggleShuffle() {
        isShuffled.toggle()
    }

    public func cycleRepeatMode() {
        switch repeatMode {
        case .off: repeatMode = .all
        case .all: repeatMode = .one
        case .one: repeatMode = .off
        }
    }

    // MARK: Sleep timer

    /// Berhenti otomatis setelah `minutes` menit.
    public func setSleepTimer(minutes: Int) {
        setSleepTimer(duration: TimeInterval(minutes * 60))
    }

    /// Berhenti otomatis setelah `duration` detik.
    public func setSleepTimer(duration: TimeInterval) {
        guard duration > 0 else {
            cancelSleepTimer()
            return
        }
        startSleepCountdown(duration)
    }

    /// Berhenti otomatis di akhir trek yang sedang diputar.
    public func setSleepTimerEndOfTrack() {
        cancelSleepTask()
        sleepTimerRemaining = nil
        sleepTimerMode = .endOfTrack
    }

    public func cancelSleepTimer() {
        cancelSleepTask()
        sleepTimerRemaining = nil
        sleepTimerMode = .off
    }

    private func startSleepCountdown(_ seconds: TimeInterval) {
        cancelSleepTask()
        sleepTimerMode = .duration(seconds)
        sleepTimerRemaining = seconds

        let deadline = Date().addingTimeInterval(seconds)
        sleepTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard let self, !Task.isCancelled else { return }

                let remaining = deadline.timeIntervalSinceNow
                if remaining <= 0 {
                    self.finishSleepTimer()
                    return
                }
                self.sleepTimerRemaining = remaining
            }
        }
    }

    private func cancelSleepTask() {
        sleepTask?.cancel()
        sleepTask = nil
    }

    private func finishSleepTimer() {
        cancelSleepTask()
        sleepTimerRemaining = nil
        sleepTimerMode = .off
        pause()
    }

    // MARK: Internals

    private func resolvedURL(for track: AudioTrack) -> URL {
        localURLResolver?(track) ?? track.streamURL
    }

    private func loadCurrent(autoPlay: Bool) {
        guard let track = current else { return }
        savePosition()

        let url = resolvedURL(for: track)
        let item = AVPlayerItem(url: url)
        player.replaceCurrentItem(with: item)

        observeEnd(of: item)

        duration = Double(track.durationSeconds ?? 0)
        currentTime = 0

        loadArtwork(for: track)
        refreshNowPlaying()

        if autoPlay {
            player.play()
            player.rate = rate
            isPlaying = true
            refreshNowPlaying()
        }
    }

    private func observeEnd(of item: AVPlayerItem) {
        if let endObserver {
            NotificationCenter.default.removeObserver(endObserver)
        }
        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { @Sendable [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                self.savePosition()
                if self.sleepTimerMode == .endOfTrack {
                    self.finishSleepTimer()
                    return
                }
                if self.repeatMode == .one {
                    self.seek(to: 0)
                    self.resume()
                } else {
                    self.next()
                }
            }
        }
    }

    private func installTimeObserver() {
        let interval = CMTime(seconds: 0.5, preferredTimescale: 600)
        timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { @Sendable [weak self] time in
            Task { @MainActor in
                guard let self else { return }
                self.currentTime = time.seconds
                if let itemDuration = self.player.currentItem?.duration.seconds,
                   itemDuration.isFinite, itemDuration > 0 {
                    self.duration = itemDuration
                }
                // Perbarui Now Playing maksimum sekali per 2 detik.
                if Date().timeIntervalSince(self.lastNowPlayingRefresh) > 2 {
                    self.refreshNowPlaying()
                }
            }
        }
    }

    // MARK: Resume posisi

    private func positionKey(for track: AudioTrack) -> String {
        positionKeyPrefix + track.url
    }

    private func savePosition() {
        guard let track = current, currentTime > 1 else { return }
        defaults.set(currentTime, forKey: positionKey(for: track))
    }

    /// Posisi tersimpan (detik) untuk sebuah trek.
    public func savedPosition(for track: AudioTrack) -> Double {
        defaults.double(forKey: positionKey(for: track))
    }

    // MARK: Now Playing & media keys

    private func configureRemoteCommands() {
        guard !remoteCommandsConfigured else { return }
        remoteCommandsConfigured = true

        let center = MPRemoteCommandCenter.shared()

        center.playCommand.addTarget { @Sendable [weak self] _ in
            Task { @MainActor in self?.resume() }
            return .success
        }
        center.pauseCommand.addTarget { @Sendable [weak self] _ in
            Task { @MainActor in self?.pause() }
            return .success
        }
        center.togglePlayPauseCommand.addTarget { @Sendable [weak self] _ in
            Task { @MainActor in self?.togglePlayPause() }
            return .success
        }
        center.nextTrackCommand.addTarget { @Sendable [weak self] _ in
            Task { @MainActor in self?.next() }
            return .success
        }
        center.previousTrackCommand.addTarget { @Sendable [weak self] _ in
            Task { @MainActor in self?.previous() }
            return .success
        }
        center.changePlaybackPositionCommand.addTarget { @Sendable [weak self] event in
            guard let positionEvent = event as? MPChangePlaybackPositionCommandEvent else {
                return .commandFailed
            }
            let target = positionEvent.positionTime
            Task { @MainActor in self?.seek(to: target) }
            return .success
        }
    }

    private func refreshNowPlaying() {
        let center = MPNowPlayingInfoCenter.default()

        guard let track = current else {
            center.nowPlayingInfo = nil
            center.playbackState = .stopped
            return
        }

        var info: [String: Any] = [
            MPMediaItemPropertyTitle: track.title,
            MPMediaItemPropertyArtist: track.reciterFolderSlug,
            MPMediaItemPropertyPlaybackDuration: duration,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: currentTime,
            MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? Double(rate) : 0,
            MPNowPlayingInfoPropertyMediaType: MPNowPlayingInfoMediaType.audio.rawValue,
        ]
        if let nowPlayingArtwork {
            info[MPMediaItemPropertyArtwork] = nowPlayingArtwork
        }

        center.nowPlayingInfo = info
        center.playbackState = isPlaying ? .playing : .paused
        lastNowPlayingRefresh = Date()
    }

    private func loadArtwork(for track: AudioTrack) {
        artworkTask?.cancel()
        nowPlayingArtwork = nil

        let url = QCEndpoints.artworkURL(for: track.reciterFolderSlug)
        artworkTask = Task { [weak self] in
            guard let (data, _) = try? await URLSession.shared.data(from: url),
                  let image = NSImage(data: data) else { return }
            guard !Task.isCancelled else { return }

            let artwork = AudioPlayer.makeArtwork(from: image)
            await MainActor.run {
                guard let self else { return }
                self.nowPlayingArtwork = artwork
                self.refreshNowPlaying()
            }
        }
    }

    /// Membuat `MPMediaItemArtwork` di konteks **nonisolated**.
    ///
    /// Penting: MediaPlayer memanggil `requestHandler` dari queue internalnya
    /// (bukan main thread). Bila closure dibuat di konteks `@MainActor`,
    /// Swift 6 akan menyimpulkan closure itu `@MainActor`-isolated dan
    /// memanggilnya dari queue lain menyebabkan `dispatch_assert_queue_fail`
    /// (SIGILL). Karena itu pembuatannya dipisah ke fungsi nonisolated.
    nonisolated static func makeArtwork(from image: NSImage) -> MPMediaItemArtwork {
        MPMediaItemArtwork(boundsSize: image.size) { _ in image }
    }
}
