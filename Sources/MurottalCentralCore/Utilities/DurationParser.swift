import Foundation

/// Mengurai format durasi yang dipakai Quran Central.
///
/// Sumber data memakai tiga bentuk: `"52"` (detik), `"28:09"` (mm:ss),
/// dan `"2:06:16"` (h:mm:ss).
public enum DurationParser {

    /// Ubah string durasi menjadi jumlah detik.
    public static func seconds(from raw: String?) -> Int? {
        guard let raw else { return nil }
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let parts = trimmed.split(separator: ":").map(String.init)
        let numbers = parts.compactMap { Int($0) }
        guard numbers.count == parts.count, !numbers.isEmpty else { return nil }

        switch numbers.count {
        case 1: return numbers[0]
        case 2: return numbers[0] * 60 + numbers[1]
        case 3: return numbers[0] * 3600 + numbers[1] * 60 + numbers[2]
        default: return nil
        }
    }

    /// Format durasi string (dari JSON) menjadi `m:ss` atau `h:mm:ss`.
    public static func formatted(from raw: String?) -> String {
        guard let total = seconds(from: raw) else { return "--:--" }
        return format(Double(total))
    }

    /// Format jumlah detik menjadi `m:ss` atau `h:mm:ss`.
    public static func format(_ total: Double) -> String {
        guard total.isFinite, total >= 0 else { return "--:--" }
        let t = Int(total.rounded())
        let hours = t / 3600
        let minutes = (t % 3600) / 60
        let seconds = t % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%d:%02d", minutes, seconds)
    }
}
