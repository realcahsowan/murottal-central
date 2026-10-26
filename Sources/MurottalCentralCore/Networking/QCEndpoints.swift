import Foundation

/// Semua endpoint publik Quran Central yang dipakai aplikasi.
public enum QCEndpoints {

    public static let dataBase = URL(string: "https://data.qurancentral.com")!
    public static let audioBase = URL(string: "https://podcasts.qurancentral.com")!
    public static let artworkBase = URL(string: "https://artwork.qurancentral.com")!

    // MARK: Katalog

    public static var reciters: URL { dataBase.appending(path: "reciters.json") }
    public static var surahs: URL { dataBase.appending(path: "surahs.json") }

    public static func category(_ slug: String) -> URL {
        dataBase.appending(path: "categories/\(slug).json")
    }

    public static func surahTag(_ slug: String) -> URL {
        dataBase.appending(path: "tags/\(slug).json")
    }

    /// Qari audio per ayat (EveryAyah), 45 entri.
    public static var ayahReciters: URL {
        dataBase.appending(path: "features/read-quran/data/list-reciters.json")
    }

    // MARK: Teks Qur'an

    public static var listSurah: URL {
        dataBase.appending(path: "features/read-quran/data/list-surah.json")
    }

    public static var listJuz: URL {
        dataBase.appending(path: "features/read-quran/data/list-juz.json")
    }

    public static var quranIndoPak: URL {
        dataBase.appending(path: "features/read-quran/data/quran-arabic-indopak.json")
    }

    public static var quranUthmaniTajweed: URL {
        dataBase.appending(path: "features/read-quran/data/quran-arabic-uthmani-tajweed.json")
    }

    public static var quranEnglishSahih: URL {
        dataBase.appending(path: "features/read-quran/data/quran-english-sahih.json")
    }

    public static var quranTransliteration: URL {
        dataBase.appending(path: "features/read-quran/data/quran_transliteration.json")
    }

    /// Teks Uthmani standar dari Quran.com (memakai U+0670 untuk alif madd,
    /// sehingga tampil benar dengan font KFGQPC).
    public static var quranComUthmani: URL {
        quranComBase.appending(path: "quran/verses/uthmani")
    }

    // MARK: Terjemahan tambahan (Quran.com API v4)

    public static let quranComBase = URL(string: "https://api.quran.com/api/v4")!

    /// Terjemahan lengkap (6.236 ayat) untuk satu resource.
    ///
    /// Contoh: `quranComTranslation(33)` → terjemahan Indonesia (Kemenag).
    public static func quranComTranslation(_ resourceID: Int) -> URL {
        quranComBase.appending(path: "quran/translations/\(resourceID)")
    }

    // MARK: Media

    public static func audioURL(for relative: String) -> URL {
        audioBase.appending(path: relative)
    }

    public static func artworkURL(for slug: String) -> URL {
        artworkBase.appending(path: "\(ArtworkResolver.artworkSlug(for: slug))-300x300.jpg")
    }

    public static var artworkFallbackMale: URL {
        dataBase.appending(path: "images/artwork-fallback.jpg")
    }

    public static var artworkFallbackFemale: URL {
        dataBase.appending(path: "images/artwork-fallback-female.jpg")
    }
}
