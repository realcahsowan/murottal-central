import Foundation

/// Menentukan slug artwork untuk sebuah qari.
///
/// Artwork diambil dari `https://artwork.qurancentral.com/{slug}-300x300.jpg`.
/// Beberapa slug kategori berbeda dengan nama folder podcast, sehingga perlu
/// tabel alias (diambil dari bundle web Quran Central).
public enum ArtworkResolver {

    /// Alias: slug kategori → slug folder podcast.
    public static let slugAliases: [String: String] = [
        "abdu-rasheed-as-sufi-khalaf": "abdu-rasheed-as-sufi",
        "abdul-basit": "abdul-basit-abd-us-samad",
        "abdul-muhsin-alqasim": "abdul-muhsin-al-qasim",
        "abdullaah-alee-jaabir-studio": "abdullah-ali-jabir",
        "abdul-rahman-al-sudais": "abdur-rahman-as-sudais",
        "abduragmaan-sadien": "abdurrahmaan-sadien",
        "ebrahim-shaaysha": "abu-aynayn-shaeesha",
        "abubukir-abduraouf": "abubakr-abduraouf",
        "ahmad-naina": "ahmed-neinaa",
        "fuaad-isaacs": "fuad-isaacs",
        "haroon-moos": "harun-moos",
        "hussein-dalvie": "husain-dalvie",
        "mufti-menk": "mufti-ismail-menk",
        "muhammad-siddiq-minshawi": "muhammad-siddiq-al-minshawi",
    ]

    /// Normalisasi slug kategori menjadi slug artwork.
    public static func artworkSlug(for slug: String) -> String {
        slugAliases[slug] ?? slug
    }

    /// Ambil komponen pertama dari URL audio relatif, lalu normalisasi.
    public static func folderSlug(fromAudioURL url: String) -> String {
        guard let first = url.split(separator: "/").first else { return "" }
        return artworkSlug(for: String(first))
    }
}
