import Foundation

/// Kontrak sumber data. Implementasi konkret (`QuranCentralClient`) bisa
/// diganti dengan provider lain (mis. mp3quran.net) tanpa mengubah UI.
public protocol QuranDataSource: Sendable {
    func reciters() async throws -> [Reciter]
    func surahs() async throws -> [Surah]
    func category(slug: String) async throws -> ReciterCategory
    func surahTag(slug: String) async throws -> SurahTag
    func juzList() async throws -> [Juz]
}

/// Kontrak khusus fitur baca: teks Qur'an & qari per ayat.
public protocol QuranTextSource: Sendable {
    /// 45 qari audio per ayat (EveryAyah).
    func ayahReciters() async throws -> [AyahReciter]
    /// Teks Uthmani standar (Quran.com, memakai U+0670).
    func quranUthmani() async throws -> [QuranVerse]
    /// Teks IndoPak (Quran Central).
    func quranIndopak() async throws -> [QuranVerse]
    /// Terjemahan Inggris (Sahih International).
    func quranEnglish() async throws -> [QuranVerse]
    /// Terjemahan tambahan dari Quran.com, dalam urutan kanonik (6.236 ayat).
    func quranTranslation(resourceID: Int) async throws -> [String]
}

/// Error yang sudah dinormalkan agar aman dikirim antar-actor (Sendable).
public enum QuranCentralError: Error, LocalizedError, Sendable, Equatable {
    case http(status: Int, url: URL)
    case decoding(message: String)
    case transport(message: String)

    public var errorDescription: String? {
        switch self {
        case let .http(status, url):
            return "Server membalas \(status) untuk \(url.lastPathComponent)."
        case let .decoding(message):
            return "Gagal membaca data: \(message)"
        case let .transport(message):
            return "Koneksi bermasalah: \(message)"
        }
    }
}
