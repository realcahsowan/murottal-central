import Foundation

/// Detail satu qari + seluruh playlist audionya.
///
/// Berasal dari `https://data.qurancentral.com/categories/{slug}.json`.
public struct ReciterCategory: Codable, Sendable {
    public let title: String
    public let description: String?
    public let image: String?
    public let female: Bool?
    public let link: String?
    public let items: [AudioTrack]

    public init(
        title: String,
        description: String? = nil,
        image: String? = nil,
        female: Bool? = nil,
        link: String? = nil,
        items: [AudioTrack]
    ) {
        self.title = title
        self.description = description
        self.image = image
        self.female = female
        self.link = link
        self.items = items
    }
}

/// Semua rekaman untuk satu surah dari berbagai qari.
///
/// Berasal dari `https://data.qurancentral.com/tags/{surah-slug}.json`.
public struct SurahTag: Codable, Sendable {
    public let title: String
    public let items: [AudioTrack]

    public init(title: String, items: [AudioTrack]) {
        self.title = title
        self.items = items
    }
}
