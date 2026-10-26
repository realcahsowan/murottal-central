import Foundation

/// Pencarian daftar qari per ayat (EveryAyah).
public enum AyahReciterSearch {

    /// Filter berdasarkan nama, subfolder, atau bitrate.
    public static func filter(_ reciters: [AyahReciter], query: String) -> [AyahReciter] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return reciters }

        return reciters.filter { reciter in
            reciter.name.localizedCaseInsensitiveContains(trimmed)
                || reciter.subfolder.localizedCaseInsensitiveContains(trimmed)
                || reciter.bitrate.localizedCaseInsensitiveContains(trimmed)
        }
    }
}
