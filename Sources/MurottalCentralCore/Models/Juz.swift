import Foundation

/// Rentang ayat (dipakai oleh Juz).
public struct VerseRef: Codable, Hashable, Sendable {
    public let surah: Int
    public let verse: Int

    public init(surah: Int, verse: Int) {
        self.surah = surah
        self.verse = verse
    }
}

/// Satu juz (1...30).
///
/// Berasal dari `.../features/read-quran/data/list-juz.json`.
public struct Juz: Codable, Identifiable, Hashable, Sendable {
    public let index: Int
    public let start: VerseRef
    public let end: VerseRef

    public var id: Int { index }

    public init(index: Int, start: VerseRef, end: VerseRef) {
        self.index = index
        self.start = start
        self.end = end
    }
}

/// Satu ayat Al-Qur'an (teks Arab / terjemahan / transliterasi).
///
/// Berasal dari `.../features/read-quran/data/quran-*.json`.
public struct QuranVerse: Codable, Hashable, Identifiable, Sendable {
    public let sura: Int
    public let ayah: Int
    public let text: String

    /// Identitas stabil, mis. `"4:148"`.
    public var id: String { "\(sura):\(ayah)" }

    public init(sura: Int, ayah: Int, text: String) {
        self.sura = sura
        self.ayah = ayah
        self.text = text
    }
}
