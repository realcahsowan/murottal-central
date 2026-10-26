import Foundation

/// Klien async untuk API publik Quran Central.
///
/// - Menyetel `User-Agent` (wajib: tanpa UA, Cloudflare membalas 403).
/// - Memakai `URLCache` untuk JSON & artwork.
/// - Men-de-duplikasi request yang identik lewat `inFlight`.
public actor QuranCentralClient: QuranDataSource, QuranTextSource {

    private let session: URLSession
    private let decoder: JSONDecoder
    private let limiter: AsyncSemaphore
    private var inFlight: [URL: Task<Data, Error>] = [:]

    public init(
        cacheSizeMB: Int = 128,
        maxConcurrentRequests: Int = 4,
        userAgent: String = "MurottalCentral/0.1 (macOS)"
    ) {
        let config = URLSessionConfiguration.default
        config.httpAdditionalHeaders = [
            "User-Agent": userAgent,
            "Accept": "application/json",
            // WAJIB: Cloudflare menolak (403) request tanpa Origin ini.
            "Origin": "https://qurancentral.com",
            "Referer": "https://qurancentral.com/",
        ]
        config.urlCache = URLCache(
            memoryCapacity: 16 * 1024 * 1024,
            diskCapacity: cacheSizeMB * 1024 * 1024
        )
        config.requestCachePolicy = .useProtocolCachePolicy
        config.waitsForConnectivity = true
        config.timeoutIntervalForRequest = 30

        self.session = URLSession(configuration: config)
        self.limiter = AsyncSemaphore(limit: maxConcurrentRequests)

        let decoder = JSONDecoder()
        self.decoder = decoder
    }

    // MARK: - QuranDataSource

    public func reciters() async throws -> [Reciter] {
        try await get(QCEndpoints.reciters)
    }

    public func surahs() async throws -> [Surah] {
        try await get(QCEndpoints.surahs)
    }

    public func category(slug: String) async throws -> ReciterCategory {
        let raw: ReciterCategory = try await get(QCEndpoints.category(slug))
        return ReciterCategory(
            title: raw.title,
            description: raw.description,
            image: raw.image,
            female: raw.female,
            link: raw.link,
            items: Self.playableTracks(raw.items)
        )
    }

    public func surahTag(slug: String) async throws -> SurahTag {
        let raw: SurahTag = try await get(QCEndpoints.surahTag(slug))
        return SurahTag(title: raw.title, items: Self.playableTracks(raw.items))
    }

    public func juzList() async throws -> [Juz] {
        try await get(QCEndpoints.listJuz)
    }

    // MARK: - QuranTextSource

    private struct AyahReciterEntry: Decodable {
        let subfolder: String
        let name: String
        let bitrate: String
    }

    public func ayahReciters() async throws -> [AyahReciter] {
        let raw: [String: AyahReciterEntry] = try await get(QCEndpoints.ayahReciters)
        return raw.compactMap { key, value in
            guard let id = Int(key) else { return nil }
            return AyahReciter(
                id: id,
                subfolder: value.subfolder,
                name: value.name,
                bitrate: value.bitrate
            )
        }
        .sorted { $0.id < $1.id }
    }

    private struct QuranComVersesResponse: Decodable {
        struct Item: Decodable {
            let verseKey: String
            let textUthmani: String

            enum CodingKeys: String, CodingKey {
                case verseKey = "verse_key"
                case textUthmani = "text_uthmani"
            }
        }
        let verses: [Item]
    }

    /// Teks Uthmani standar dari Quran.com.
    ///
    /// Memakai U+0670 (superscript alef) untuk alif madd — berbeda dari teks
    /// tajweed Quran Central yang memakai U+0672 dan tampil sebagai bulatan
    /// pada font KFGQPC.
    public func quranUthmani() async throws -> [QuranVerse] {
        let response: QuranComVersesResponse = try await get(QCEndpoints.quranComUthmani)
        return response.verses.compactMap { item in
            let parts = item.verseKey.split(separator: ":")
            guard parts.count == 2,
                  let sura = Int(parts[0]),
                  let ayah = Int(parts[1]) else { return nil }
            return QuranVerse(sura: sura, ayah: ayah, text: item.textUthmani)
        }
    }

    /// Teks IndoPak dari Quran Central.
    public func quranIndopak() async throws -> [QuranVerse] {
        try await get(QCEndpoints.quranIndoPak)
    }

    public func quranEnglish() async throws -> [QuranVerse] {
        try await get(QCEndpoints.quranEnglishSahih)
    }

    private struct QuranComTranslationResponse: Decodable {
        struct Item: Decodable {
            let text: String
        }
        let translations: [Item]
    }

    public func quranTranslation(resourceID: Int) async throws -> [String] {
        let response: QuranComTranslationResponse = try await get(
            QCEndpoints.quranComTranslation(resourceID)
        )
        return response.translations.map(\.text)
    }

    // MARK: - Internals

    /// Buang trek tanpa URL dan trek promosi/donasi (perilaku sama dengan web).
    static func playableTracks(_ items: [AudioTrack]) -> [AudioTrack] {
        items.filter { track in
            track.isPlayable && !track.url.contains("donation-appeal")
        }
    }

    private func get<T: Decodable>(_ url: URL) async throws -> T {
        let data = try await fetch(url)
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw QuranCentralError.decoding(message: String(describing: error))
        }
    }

    /// Kosongkan cache HTTP (JSON & artwork).
    public func clearCache() {
        session.configuration.urlCache?.removeAllCachedResponses()
    }

    private func fetch(_ url: URL) async throws -> Data {
        if let existing = inFlight[url] {
            return try await existing.value
        }

        // Batasi jumlah request bersamaan agar tidak diblokir Cloudflare.
        await limiter.wait()

        let session = self.session
        let task = Task<Data, Error> {
            var request = URLRequest(url: url)
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            let (data, response) = try await session.data(for: request)

            guard let http = response as? HTTPURLResponse else {
                throw QuranCentralError.transport(message: "Respons tidak valid.")
            }
            guard (200..<300).contains(http.statusCode) else {
                throw QuranCentralError.http(status: http.statusCode, url: url)
            }
            return data
        }

        inFlight[url] = task

        do {
            let data = try await task.value
            inFlight[url] = nil
            await limiter.signal()
            return data
        } catch {
            inFlight[url] = nil
            await limiter.signal()

            if let known = error as? QuranCentralError { throw known }
            throw QuranCentralError.transport(message: error.localizedDescription)
        }
    }
}
