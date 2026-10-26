import Foundation

/// Mengelola unduhan audio untuk pemutaran offline.
///
/// Berkas disimpan di
/// `~/Library/Application Support/MurottalCentral/Audio/{folderQari}/{namaBerkas}`.
/// Sebuah `manifest.json` menyimpan pemetaan `track.url → path relatif` supaya
/// resolusi berkas lokal bisa dilakukan tanpa I/O berat.
///
/// Mendukung **jeda/lanjut** lewat `resumeData` (disimpan di `.resume/`),
/// sehingga unduhan besar bisa dilanjutkan bahkan setelah app ditutup.
public actor DownloadManager {

    public enum DownloadError: Error, LocalizedError, Sendable {
        case badResponse(Int)
        case fileMissing
        case alreadyDownloading
        /// Dijeda oleh pengguna (bukan kegagalan).
        case paused
        /// Dibatalkan oleh pengguna.
        case cancelled

        public var errorDescription: String? {
            switch self {
            case let .badResponse(code): return "Unduhan gagal (HTTP \(code))."
            case .fileMissing: return "Berkas tidak ditemukan."
            case .alreadyDownloading: return "Unduhan sedang berjalan."
            case .paused: return "Unduhan dijeda."
            case .cancelled: return "Unduhan dibatalkan."
            }
        }
    }

    private let root: URL
    private let session: URLSession
    private let delegate: DownloadDelegate
    private let status: DownloadStatusStore
    private let fileManager = FileManager.default

    private var manifest: [String: String] = [:]      // track.url -> relative path
    private var resumeData: [String: Data] = [:]      // track.url -> resume data
    private var tasks: [String: URLSessionDownloadTask] = [:]
    private var active: Set<String> = []
    private var cancelling: Set<String> = []

    public init(root: URL? = nil, status: DownloadStatusStore) {
        let base = root ?? DownloadManager.defaultRoot()
        self.root = base
        self.status = status

        let config = URLSessionConfiguration.default
        config.httpAdditionalHeaders = ["User-Agent": "MurottalCentral/0.1 (macOS)"]

        let delegate = DownloadDelegate()
        self.delegate = delegate
        self.session = URLSession(
            configuration: config,
            delegate: delegate,
            delegateQueue: nil
        )

        try? fileManager.createDirectory(at: base, withIntermediateDirectories: true)
    }

    public static func defaultRoot() -> URL {
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first ?? FileManager.default.temporaryDirectory
        return appSupport
            .appending(path: "MurottalCentral")
            .appending(path: "Audio")
    }

    private var manifestURL: URL { root.appending(path: "manifest.json") }
    private var resumeDirectory: URL { root.appending(path: ".resume") }

    // MARK: - Manifest & resume data

    /// Muat manifest + data resume dari disk (panggil sekali di awal).
    public func loadManifest() {
        if let data = try? Data(contentsOf: manifestURL),
           let decoded = try? JSONDecoder().decode([String: String].self, from: data) {
            manifest = decoded
        }
        loadResumeData()
    }

    private func loadResumeData() {
        guard let names = try? fileManager.contentsOfDirectory(atPath: resumeDirectory.path) else {
            return
        }

        for name in names where name.hasSuffix(".resume") {
            let file = resumeDirectory.appending(path: name)
            guard let data = try? Data(contentsOf: file) else { continue }
            resumeData[file.deletingPathExtension().lastPathComponent] = data
        }
    }

    private func resumeFileURL(for key: String) -> URL {
        // Nama berkas tidak boleh memuat "/", jadi disandikan.
        let encoded = Data(key.utf8).base64EncodedString()
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "+", with: "-")
        return resumeDirectory.appending(path: "\(encoded).resume")
    }

    private func persistManifest() {
        guard let data = try? JSONEncoder().encode(manifest) else { return }
        try? data.write(to: manifestURL, options: .atomic)
    }

    private func storeResumeData(_ data: Data?, for key: String) {
        if let data {
            resumeData[key] = data
            try? fileManager.createDirectory(at: resumeDirectory, withIntermediateDirectories: true)
            try? data.write(to: resumeFileURL(for: key), options: .atomic)
        } else {
            resumeData[key] = nil
            try? fileManager.removeItem(at: resumeFileURL(for: key))
        }
    }

    /// `true` bila ada unduhan yang bisa dilanjutkan untuk trek ini.
    public func canResume(_ track: AudioTrack) -> Bool {
        resumeData[track.url] != nil
    }

    // MARK: - Path

    private func relativePath(for track: AudioTrack) -> String {
        let folder = track.downloadFolder.isEmpty ? "misc" : track.downloadFolder
        return "\(folder)/\(track.fileName)"
    }

    private func destinationURL(for track: AudioTrack) -> URL {
        root.appending(path: relativePath(for: track))
    }

    /// Lokasi berkas lokal bila sudah diunduh.
    public func localURL(for track: AudioTrack) -> URL? {
        let url = destinationURL(for: track)
        return fileManager.fileExists(atPath: url.path) ? url : nil
    }

    /// Snapshot pemetaan `track.url → URL lokal` untuk dipakai UI (sinkron).
    public func localURLMap() -> [String: URL] {
        var result: [String: URL] = [:]
        for (key, relative) in manifest {
            let url = root.appending(path: relative)
            if fileManager.fileExists(atPath: url.path) {
                result[key] = url
            }
        }
        return result
    }

    public func isDownloaded(_ track: AudioTrack) -> Bool {
        localURL(for: track) != nil
    }

    public func isDownloading(_ track: AudioTrack) -> Bool {
        active.contains(track.url)
    }

    // MARK: - Aksi

    @discardableResult
    public func download(_ track: AudioTrack) async throws -> URL {
        if let existing = localURL(for: track) {
            await status.set(.downloaded, for: track.url)
            storeResumeData(nil, for: track.url)
            return existing
        }
        guard !active.contains(track.url) else {
            throw DownloadError.alreadyDownloading
        }

        let key = track.url
        active.insert(key)
        cancelling.remove(key)
        defer { active.remove(key) }

        await status.set(.downloading(progress: resumeData[key] != nil ? 0 : -1), for: key)

        let destination = destinationURL(for: track)
        let statusStore = status
        let delegate = self.delegate
        let existingResumeData = resumeData[key]

        let holding: URL
        do {
            holding = try await withCheckedThrowingContinuation { continuation in
                let task: URLSessionDownloadTask
                if let existingResumeData {
                    task = session.downloadTask(withResumeData: existingResumeData)
                } else {
                    task = session.downloadTask(with: track.streamURL)
                }
                tasks[key] = task

                delegate.register(
                    taskIdentifier: task.taskIdentifier,
                    onProgress: { progress in
                        Task { @MainActor in
                            statusStore.set(.downloading(progress: progress), for: key)
                        }
                    },
                    onFinish: { result in
                        continuation.resume(with: result)
                    }
                )
                task.resume()
            }
        } catch DownloadError.paused {
            tasks[key] = nil
            throw DownloadError.paused
        } catch {
            tasks[key] = nil
            if cancelling.remove(key) != nil {
                storeResumeData(nil, for: key)
                await status.set(.notDownloaded, for: key)
                throw DownloadError.cancelled
            }
            await status.set(.failed(error.localizedDescription), for: key)
            throw error
        }

        tasks[key] = nil

        try fileManager.createDirectory(
            at: destination.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        if fileManager.fileExists(atPath: destination.path) {
            try fileManager.removeItem(at: destination)
        }
        try fileManager.moveItem(at: holding, to: destination)

        manifest[key] = relativePath(for: track)
        persistManifest()
        storeResumeData(nil, for: key)
        await status.set(.downloaded, for: key)
        return destination
    }

    /// Jeda unduhan yang sedang berjalan; menyimpan `resumeData`.
    public func pause(_ track: AudioTrack) async {
        let key = track.url
        guard let task = tasks[key] else { return }
        let progress = delegate.lastProgress(for: task.taskIdentifier)

        let data = await task.cancelByProducingResumeData()
        storeResumeData(data, for: key)
        await status.set(.paused(progress: progress), for: key)
    }

    /// Batalkan unduhan dan buang data resume-nya.
    public func cancel(_ track: AudioTrack) async {
        let key = track.url
        cancelling.insert(key)
        storeResumeData(nil, for: key)
        await status.set(.notDownloaded, for: key)
        tasks[key]?.cancel()
    }

    public func delete(_ track: AudioTrack) throws {
        guard let url = localURL(for: track) else { throw DownloadError.fileMissing }
        try fileManager.removeItem(at: url)
        manifest[track.url] = nil
        persistManifest()
        storeResumeData(nil, for: track.url)
    }

    public func deleteAll() throws {
        guard fileManager.fileExists(atPath: root.path) else { return }
        try fileManager.removeItem(at: root)
        try fileManager.createDirectory(at: root, withIntermediateDirectories: true)
        manifest = [:]
        resumeData = [:]
        persistManifest()
    }

    /// Total ukuran berkas yang sudah diunduh (byte).
    public func totalSize() -> Int64 {
        guard let enumerator = fileManager.enumerator(
            at: root,
            includingPropertiesForKeys: [.fileSizeKey]
        ) else { return 0 }

        var total: Int64 = 0
        for case let url as URL in enumerator where url.pathExtension == "mp3" {
            let size = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
            total += Int64(size)
        }
        return total
    }
}
