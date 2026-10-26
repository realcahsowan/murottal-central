import Foundation

/// Membersihkan markup pada teks Qur'an dari API Quran Central.
///
/// Teks `quran-arabic-uthmani-tajweed.json` memuat markup seperti
/// `<tajweed class=ghunnah>…</tajweed>` dan penanda akhir ayat
/// `<span class=end>٣</span>`. Karena aplikasi ini tidak mewarnai tajwid dan
/// menampilkan nomor ayat sendiri, seluruh tag dibuang, termasuk penanda akhir.
public enum QuranTextSanitizer {

    /// Buang tag HTML/tajwid, footnote, dan penanda akhir ayat.
    public static func plain(_ text: String) -> String {
        // Footnote Quran.com: <sup foot_note=135189>1</sup> — buang seluruhnya.
        let withoutFootnotes = text.replacingOccurrences(
            of: "<sup[^>]*>[^<]*</sup>",
            with: "",
            options: .regularExpression
        )
        let withoutEndMarker = withoutFootnotes.replacingOccurrences(
            of: "<span class=end>[^<]*</span>",
            with: "",
            options: .regularExpression
        )
        let withoutTags = withoutEndMarker.replacingOccurrences(
            of: "<[^>]+>",
            with: "",
            options: .regularExpression
        )
        let collapsed = withoutTags.replacingOccurrences(
            of: "[ \\t]+",
            with: " ",
            options: .regularExpression
        )
        return collapsed.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Versi tampilan.
    public static func display(_ text: String) -> String {
        plain(text)
    }
}
