import Foundation

/// Referensi ringan ke seorang qari (untuk koleksi/riwayat, tanpa memuat katalog).
public struct ReciterRef: Codable, Hashable, Identifiable, Sendable {
    public let slug: String
    public let name: String

    public var id: String { slug }

    public init(slug: String, name: String) {
        self.slug = slug
        self.name = name
    }
}

/// Satu entri riwayat pemutaran.
public struct HistoryEntry: Codable, Hashable, Identifiable, Sendable {
    public let url: String
    public let title: String
    public let reciterName: String
    public let playedAt: Date

    public var id: String { url }

    public init(url: String, title: String, reciterName: String, playedAt: Date = .now) {
        self.url = url
        self.title = title
        self.reciterName = reciterName
        self.playedAt = playedAt
    }
}
