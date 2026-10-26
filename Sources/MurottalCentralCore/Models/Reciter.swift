import Foundation

/// Seorang qari (perawi) beserta metadata katalog.
///
/// Berasal dari `https://data.qurancentral.com/reciters.json`.
public struct Reciter: Codable, Identifiable, Hashable, Sendable {
    public let id: Int
    public let slug: String
    public let name: String
    /// Jumlah berkas audio yang tersedia untuk qari ini.
    public let postCount: Int
    public let country: String?
    public let dialect: String?
    /// `true` untuk qari perempuan (opsional di sumber data).
    public let female: Bool?
    /// `true` untuk penanda gaya mujawwad (opsional di sumber data).
    public let mujawwad: Bool?

    public init(
        id: Int,
        slug: String,
        name: String,
        postCount: Int,
        country: String? = nil,
        dialect: String? = nil,
        female: Bool? = nil,
        mujawwad: Bool? = nil
    ) {
        self.id = id
        self.slug = slug
        self.name = name
        self.postCount = postCount
        self.country = country
        self.dialect = dialect
        self.female = female
        self.mujawwad = mujawwad
    }

    enum CodingKeys: String, CodingKey {
        case id, slug, name, country, dialect, female, mujawwad
        case postCount = "post_count"
    }
}

public extension Reciter {
    var hasAudio: Bool { postCount > 0 }
    var countryLabel: String { country ?? "Unknown" }
    var dialectLabel: String { dialect ?? "Unknown" }

    /// `true` bila bukan qari perempuan. Field `female` absen = laki-laki.
    var isMale: Bool { female != true }
}

/// Kebijakan penyaringan katalog.
public enum ReciterFilter {

    /// Hanya qari laki-laki.
    ///
    /// Ini adalah kebijakan aplikasi Murottal Central: katalog yang ditampilkan
    /// (daftar qari, pencarian, qari berbintang, Haramain) hanya memuat qari
    /// laki-laki. Ubah di sini bila kebijakan berubah.
    public static func malesOnly(_ reciters: [Reciter]) -> [Reciter] {
        reciters.filter(\.isMale)
    }
}
