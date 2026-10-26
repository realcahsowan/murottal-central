import Foundation

/// Logika pencarian & filter katalog (dipakai grid qari dan layar pencarian).
///
/// Dipisahkan dari UI agar bisa diuji tanpa SwiftUI.
public enum CatalogSearch {

    /// Filter qari berdasarkan kata kunci, negara, dan dialek.
    /// Nilai `country`/`dialect` yang `nil` atau kosong berarti "semua".
    public static func reciters(
        _ all: [Reciter],
        query: String,
        country: String? = nil,
        dialect: String? = nil
    ) -> [Reciter] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)

        return all.filter { reciter in
            if !trimmed.isEmpty {
                let matches = reciter.name.localizedCaseInsensitiveContains(trimmed)
                    || reciter.slug.localizedCaseInsensitiveContains(trimmed)
                if !matches { return false }
            }
            if let country, !country.isEmpty, reciter.countryLabel != country {
                return false
            }
            if let dialect, !dialect.isEmpty, reciter.dialectLabel != dialect {
                return false
            }
            return true
        }
    }

    /// Filter surah berdasarkan nomor, nama latin, arti, atau nama Arab.
    public static func surahs(_ all: [Surah], query: String) -> [Surah] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return all }

        return all.filter { surah in
            surah.transliteration.localizedCaseInsensitiveContains(trimmed)
                || surah.translation.localizedCaseInsensitiveContains(trimmed)
                || surah.arabic.contains(trimmed)
                || String(surah.id) == trimmed
                || String(format: "%03d", surah.id) == trimmed
        }
    }

    /// Daftar negara unik (terurut) untuk picker filter.
    public static func countries(in all: [Reciter]) -> [String] {
        Set(all.map(\.countryLabel)).sorted()
    }

    /// Daftar dialek unik (terurut) untuk picker filter.
    public static func dialects(in all: [Reciter]) -> [String] {
        Set(all.map(\.dialectLabel)).sorted()
    }

    /// Filter trek di dalam sebuah playlist (mis. playlist qari atau tag surah).
    public static func tracks(_ all: [AudioTrack], query: String) -> [AudioTrack] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return all }

        return all.filter { track in
            track.title.localizedCaseInsensitiveContains(trimmed)
                || track.fileName.localizedCaseInsensitiveContains(trimmed)
        }
    }
}
