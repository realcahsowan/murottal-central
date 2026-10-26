import Foundation
import MurottalCentralCore
import Observation

/// State global aplikasi: katalog, pemutar, koleksi, unduhan.
@MainActor
@Observable
public final class AppState {

    public let client: QuranCentralClient
    public let player: AudioPlayer
    public let favorites: FavoritesStore
    public let history: PlaybackHistoryStore
    public let downloadStatus: DownloadStatusStore
    public let downloads: DownloadManager

    // Katalog
    public private(set) var reciters: [Reciter] = []
    public private(set) var surahs: [Surah] = []
    public private(set) var juz: [Juz] = []
    public private(set) var isLoadingCatalog = false
    public private(set) var catalogError: String?
    public private(set) var juzError: String?

    /// Bagian yang sedang dipilih di sidebar (juga dikendalikan lewat menu).
    var selection: SidebarItem? = .reciters

    // Cache
    private var categoryCache: [String: ReciterCategory] = [:]
    private var surahTagCache: [String: SurahTag] = [:]
    private var juzLoaded = false

    // Membaca (teks + audio per ayat)
    public private(set) var ayahReciters: [AyahReciter] = []
    public var selectedAyahReciterID: Int = 20   // default: Al-Husary (sama seperti web)
    public private(set) var quranUthmaniVerses: [QuranVerse] = []
    public private(set) var quranIndopakVerses: [QuranVerse] = []
    public private(set) var quranEnglishVerses: [QuranVerse] = []
    public private(set) var isLoadingReading = false
    public private(set) var readingError: String?

    private var readingLoaded = false
    private var englishIndex: [String: String] = [:]
    private var indonesianIndex: [String: String] = [:]
    private var indonesianLoaded = false
    private var isLoadingIndonesian = false

    /// Pemetaan `track.url → berkas lokal` (diperbarui setelah unduhan).
    public private(set) var downloadedURLs: [String: URL] = [:]

    public init() {
        let client = QuranCentralClient()
        let player = AudioPlayer()
        let status = DownloadStatusStore()
        let downloads = DownloadManager(status: status)

        self.client = client
        self.player = player
        self.favorites = FavoritesStore()
        self.history = PlaybackHistoryStore()
        self.downloadStatus = status
        self.downloads = downloads

        player.localURLResolver = { [weak self] track in
            self?.downloadedURLs[track.url]
        }
    }

    /// Dipanggil sekali saat aplikasi mulai.
    public func start() async {
        await downloads.loadManifest()
        await refreshDownloads()
        await loadCatalogIfNeeded()
    }

    // MARK: - Katalog

    public func loadCatalogIfNeeded() async {
        guard reciters.isEmpty, !isLoadingCatalog else { return }
        await reloadCatalog()
    }

    public func reloadCatalog() async {
        isLoadingCatalog = true
        catalogError = nil
        defer { isLoadingCatalog = false }

        do {
            async let recitersTask = client.reciters()
            async let surahsTask = client.surahs()
            // Kebijakan aplikasi: hanya tampilkan qari laki-laki.
            reciters = ReciterFilter.malesOnly(try await recitersTask)
            surahs = try await surahsTask
        } catch {
            catalogError = Self.message(for: error)
        }
    }

    public func loadJuzIfNeeded() async {
        guard !juzLoaded else { return }
        juzError = nil
        do {
            juz = try await client.juzList()
            juzLoaded = true
        } catch {
            juzError = Self.message(for: error)
        }
    }

    /// Cari qari di katalog berdasarkan slug.
    public func reciter(slug: String) -> Reciter? {
        reciters.first { $0.slug == slug }
    }

    /// Qari dari katalog, atau referensi sintetis bila belum termuat.
    public func reciterOrPlaceholder(slug: String, name: String) -> Reciter {
        reciter(slug: slug)
            ?? Reciter(id: 0, slug: slug, name: name, postCount: 0)
    }

    // MARK: - Membaca (teks & audio per ayat)

    /// Qari per ayat yang sedang dipilih.
    public var selectedAyahReciter: AyahReciter? {
        ayahReciters.first { $0.id == selectedAyahReciterID } ?? ayahReciters.first
    }

    /// Muat daftar qari per ayat + teks Qur'an (sekali saja).
    public func loadReadingIfNeeded() async {
        guard !readingLoaded, !isLoadingReading else { return }
        isLoadingReading = true
        readingError = nil
        defer { isLoadingReading = false }

        do {
            async let recitersTask = client.ayahReciters()
            async let uthmaniTask = client.quranUthmani()
            async let indopakTask = client.quranIndopak()
            async let englishTask = client.quranEnglish()

            ayahReciters = try await recitersTask
            quranUthmaniVerses = try await uthmaniTask
            quranIndopakVerses = try await indopakTask
            quranEnglishVerses = try await englishTask

            var index: [String: String] = [:]
            index.reserveCapacity(quranEnglishVerses.count)
            for verse in quranEnglishVerses {
                index[verse.id] = verse.text
            }
            englishIndex = index

            if !ayahReciters.contains(where: { $0.id == selectedAyahReciterID }) {
                selectedAyahReciterID = ayahReciters.first?.id ?? selectedAyahReciterID
            }
            readingLoaded = true
        } catch {
            readingError = Self.message(for: error)
        }
    }

    /// Ayat-ayat untuk sebuah cakupan baca (surah atau juz), sesuai font.
    ///
    /// Teks Uthmani diambil dari Quran.com (U+0670) agar alif madd tampil benar
    /// dengan font KFGQPC; teks IndoPak dari Quran Central.
    func readingVerses(for scope: ReadingScope, font: QuranFont) -> [QuranVerse] {
        let source: [QuranVerse]
        if font == .indopak, !quranIndopakVerses.isEmpty {
            source = quranIndopakVerses
        } else {
            source = quranUthmaniVerses
        }

        switch scope {
        case let .surah(surah):
            return source.filter { $0.sura == surah.id }

        case let .juz(juz):
            let start = juz.start
            let end = juz.end
            return source.filter { verse in
                if start.surah == end.surah {
                    return verse.sura == start.surah
                        && verse.ayah >= start.verse
                        && verse.ayah <= end.verse
                }
                if verse.sura == start.surah { return verse.ayah >= start.verse }
                if verse.sura == end.surah { return verse.ayah <= end.verse }
                return verse.sura > start.surah && verse.sura < end.surah
            }
        }
    }

    /// Terjemahan Inggris untuk sebuah ayat.
    public func englishText(for verse: QuranVerse) -> String? {
        englishIndex[verse.id]
    }

    /// Muat terjemahan tambahan (mis. Indonesia dari Quran.com) bila diperlukan.
    public func loadTranslation(_ language: TranslationLanguage) async {
        guard let resourceID = language.quranComResourceID else { return }
        guard !indonesianLoaded, !isLoadingIndonesian, !quranUthmaniVerses.isEmpty else {
            return
        }

        isLoadingIndonesian = true
        readingError = nil
        defer { isLoadingIndonesian = false }

        do {
            let texts = try await client.quranTranslation(resourceID: resourceID)
            guard texts.count == quranUthmaniVerses.count else {
                readingError = "Jumlah ayat terjemahan tidak sesuai "
                    + "(\(texts.count) dari \(quranUthmaniVerses.count))."
                return
            }

            var index: [String: String] = [:]
            index.reserveCapacity(texts.count)
            for (verse, text) in zip(quranUthmaniVerses, texts) {
                index[verse.id] = QuranTextSanitizer.plain(text)
            }
            indonesianIndex = index
            indonesianLoaded = true
        } catch {
            readingError = Self.message(for: error)
        }
    }

    /// Teks terjemahan untuk sebuah ayat sesuai bahasa yang dipilih.
    public func translationText(
        for verse: QuranVerse,
        language: TranslationLanguage
    ) -> String? {
        switch language {
        case .none: return nil
        case .english: return englishIndex[verse.id]
        case .indonesian: return indonesianIndex[verse.id]
        }
    }

    /// Putar satu ayat; queue berisi seluruh ayat pada cakupan sehingga
    /// pemutaran berlanjut otomatis ke ayat berikutnya.
    public func playVerse(_ verse: QuranVerse, in verses: [QuranVerse]) {
        guard let reciter = selectedAyahReciter, !verses.isEmpty else { return }

        let tracks = verses.map {
            AudioTrack.ayah(surah: $0.sura, ayah: $0.ayah, reciter: reciter)
        }
        let index = verses.firstIndex { $0.id == verse.id } ?? 0

        player.play(tracks, startingAt: index)
        history.record(
            url: tracks[index].url,
            title: tracks[index].title,
            reciterName: reciter.name
        )
    }

    /// Putar seluruh halaman (surah/juz) dari ayat pertama.
    public func playPage(_ verses: [QuranVerse]) {
        guard let first = verses.first else { return }
        playVerse(first, in: verses)
    }

    /// Apakah ayat ini sedang diputar.
    public func isPlayingVerse(_ verse: QuranVerse) -> Bool {
        guard let reciter = selectedAyahReciter else { return false }
        let url = EveryAyah.audioURL(
            reciter: reciter,
            surah: verse.sura,
            ayah: verse.ayah
        ).absoluteString
        return player.current?.url == url
    }

    /// ID ayat yang sedang diputar (untuk auto-scroll), bila ada.
    public var currentReadingVerseID: String? {
        guard let reciter = selectedAyahReciter,
              let current = player.current,
              current.isAbsoluteURL else { return nil }

        let prefix = EveryAyah.baseURL
            .appending(path: reciter.subfolder)
            .absoluteString + "/"
        guard current.url.hasPrefix(prefix) else { return nil }

        let file = current.fileName  // 004148.mp3
        guard file.count == 10, file.hasSuffix(".mp3") else { return nil }
        let digits = file.prefix(6)
        guard let surah = Int(digits.prefix(3)),
              let ayah = Int(digits.suffix(3)) else { return nil }
        return "\(surah):\(ayah)"
    }

    // MARK: - Detail

    public func category(for slug: String) async throws -> ReciterCategory {
        if let cached = categoryCache[slug] { return cached }
        let value = try await client.category(slug: slug)
        categoryCache[slug] = value
        return value
    }

    public func surahTag(for slug: String) async throws -> SurahTag {
        if let cached = surahTagCache[slug] { return cached }
        let value = try await client.surahTag(slug: slug)
        surahTagCache[slug] = value
        return value
    }

    // MARK: - Pemutaran

    public func play(_ track: AudioTrack, in playlist: [AudioTrack], reciterName: String) {
        let index = playlist.firstIndex(of: track) ?? 0
        player.play(playlist, startingAt: index)
        history.record(url: track.url, title: track.title, reciterName: reciterName)
    }

    // MARK: - Unduhan

    public func refreshDownloads() async {
        downloadedURLs = await downloads.localURLMap()
    }

    public func download(_ track: AudioTrack) async {
        do {
            try await downloads.download(track)
            await refreshDownloads()
        } catch DownloadManager.DownloadError.paused {
            // Dijeda oleh pengguna — bukan error.
        } catch DownloadManager.DownloadError.cancelled {
            // Dibatalkan oleh pengguna.
        } catch {
            print("Unduhan gagal: \(error.localizedDescription)")
        }
    }

    public func pauseDownload(_ track: AudioTrack) async {
        await downloads.pause(track)
    }

    public func cancelDownload(_ track: AudioTrack) async {
        await downloads.cancel(track)
        await refreshDownloads()
    }

    public func deleteDownload(_ track: AudioTrack) async {
        try? await downloads.delete(track)
        await refreshDownloads()
    }

    public func deleteAllDownloads() async {
        try? await downloads.deleteAll()
        downloadStatus.removeAll()
        await refreshDownloads()
    }

    public func isDownloaded(_ track: AudioTrack) -> Bool {
        downloadedURLs[track.url] != nil
    }

    /// Status unduhan terkini untuk sebuah trek.
    public func downloadState(for track: AudioTrack) -> DownloadState {
        if downloadedURLs[track.url] != nil { return .downloaded }
        return downloadStatus.state(for: track.url)
    }

    public func downloadSize() async -> Int64 {
        await downloads.totalSize()
    }

    // MARK: - Cache

    public func clearCaches() async {
        categoryCache.removeAll()
        surahTagCache.removeAll()
        await client.clearCache()
    }

    // MARK: - Helpers

    private static func message(for error: Error) -> String {
        (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
    }
}
