import Foundation

/// Satu surah Al-Qur'an.
///
/// Berasal dari `https://data.qurancentral.com/surahs.json`.
public struct Surah: Codable, Identifiable, Hashable, Sendable {
    /// Nomor surah 1...114 (field JSON `ID`).
    public let id: Int
    /// Nama latin tanpa diakritik (field JSON `Trans`).
    public let transliteration: String
    /// Nama Arab (field JSON `Arabic`).
    public let arabic: String
    /// Arti nama (field JSON `Translation`).
    public let translation: String
    public let homepage: Bool?
    public let slug: String
    public let description: String?

    public init(
        id: Int,
        transliteration: String,
        arabic: String,
        translation: String,
        homepage: Bool? = nil,
        slug: String,
        description: String? = nil
    ) {
        self.id = id
        self.transliteration = transliteration
        self.arabic = arabic
        self.translation = translation
        self.homepage = homepage
        self.slug = slug
        self.description = description
    }

    enum CodingKeys: String, CodingKey {
        case id = "ID"
        case transliteration = "Trans"
        case arabic = "Arabic"
        case translation = "Translation"
        case homepage, slug, description
    }
}

public extension Surah {
    /// "001 — Al Faatiha"
    var displayTitle: String {
        String(format: "%03d — %@", id, transliteration)
    }
}
