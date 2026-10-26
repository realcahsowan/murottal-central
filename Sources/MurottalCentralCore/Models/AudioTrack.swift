import Foundation

/// Satu berkas audio (unit terkecil yang bisa diputar).
///
/// `url` biasanya **relatif** terhadap `https://podcasts.qurancentral.com`
/// (audio per surah dari Quran Central), tetapi bisa juga berupa **URL absolut**
/// untuk audio per ayat dari EveryAyah.
///
/// Catatan: sebagian entri di `tags/*.json` punya `url: null`. Nilai itu
/// dinormalkan menjadi string kosong (meniru perilaku web), lalu dibuang oleh
/// `QuranCentralClient`. Gunakan `isPlayable` untuk memeriksanya.
public struct AudioTrack: Codable, Hashable, Identifiable, Sendable {
    public let title: String
    public let description: String?
    /// Format bervariasi: `"52"`, `"28:09"`, atau `"2:06:16"`.
    public let duration: String?
    /// Path relatif **atau** URL absolut (untuk audio per ayat).
    public let url: String
    /// Slug qari untuk artwork, bila berbeda dari folder audio.
    public let artworkSlug: String?

    public var id: String { url.isEmpty ? title : url }

    public init(
        title: String,
        description: String? = nil,
        duration: String? = nil,
        url: String,
        artworkSlug: String? = nil
    ) {
        self.title = title
        self.description = description
        self.duration = duration
        self.url = url
        self.artworkSlug = artworkSlug
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.title = try container.decode(String.self, forKey: .title)
        self.description = try container.decodeIfPresent(String.self, forKey: .description)
        self.duration = try container.decodeIfPresent(String.self, forKey: .duration)
        self.url = try container.decodeIfPresent(String.self, forKey: .url) ?? ""
        self.artworkSlug = try container.decodeIfPresent(String.self, forKey: .artworkSlug)
    }

    enum CodingKeys: String, CodingKey {
        case title, description, duration, url, artworkSlug
    }

    /// `true` bila berkas bisa diputar/diunduh.
    public var isPlayable: Bool { !url.isEmpty }

    /// `true` bila `url` sudah berupa URL absolut.
    public var isAbsoluteURL: Bool {
        URL(string: url)?.scheme != nil
    }

    /// URL absolut siap dipakai `AVPlayer`.
    public var streamURL: URL {
        if let absolute = URL(string: url), absolute.scheme != nil {
            return absolute
        }
        return QCEndpoints.audioURL(for: url)
    }

    /// Durasi dalam detik (jika bisa diparse).
    public var durationSeconds: Int? { DurationParser.seconds(from: duration) }

    /// Durasi terformat, mis. `"2:06:16"`; `"--:--"` bila tidak diketahui.
    public var formattedDuration: String { DurationParser.formatted(from: duration) }

    /// Slug folder qari dari URL relatif, mis. `"mishary-rashid-alafasy"`.
    public var reciterFolderSlug: String {
        if let artworkSlug, !artworkSlug.isEmpty { return artworkSlug }
        return ArtworkResolver.folderSlug(fromAudioURL: url)
    }

    /// Slug artwork, atau `nil` bila tidak diketahui (mis. audio per ayat).
    public var artworkIdentifier: String? {
        if let artworkSlug, !artworkSlug.isEmpty { return artworkSlug }
        if isAbsoluteURL { return nil }
        let slug = ArtworkResolver.folderSlug(fromAudioURL: url)
        return slug.isEmpty ? nil : slug
    }

    /// Folder penyimpanan unduhan (aman untuk URL absolut).
    public var downloadFolder: String {
        if isAbsoluteURL {
            return "ayah-" + (artworkSlug ?? "everyayah")
        }
        return ArtworkResolver.folderSlug(fromAudioURL: url)
    }

    /// Nama berkas audio saja.
    public var fileName: String {
        url.split(separator: "/").last.map(String.init) ?? url
    }
}

// MARK: - Audio per ayat

public extension AudioTrack {
    /// Trek audio satu ayat dari EveryAyah.
    static func ayah(
        surah: Int,
        ayah: Int,
        reciter: AyahReciter,
        surahName: String? = nil
    ) -> AudioTrack {
        AudioTrack(
            title: String(format: "%03d:%03d", surah, ayah),
            description: surahName,
            duration: nil,
            url: EveryAyah.audioURL(reciter: reciter, surah: surah, ayah: ayah).absoluteString,
            artworkSlug: nil
        )
    }
}
