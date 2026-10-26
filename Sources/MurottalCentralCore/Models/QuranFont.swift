import Foundation

/// Font untuk teks Arab di layar Baca.
///
/// Dua font pertama adalah font yang dipakai Quran Central di web
/// (`UthmanicHafs1Ver18.woff2` dan `indopak-nastaleeq-waqf-lazim-v4.2.1.woff2`),
/// yang telah dikonversi ke TTF agar bisa dibaca Core Text.
public enum QuranFont: String, CaseIterable, Identifiable, Sendable {
    case uthmani
    case indopak
    case system

    public var id: String { rawValue }

    public var label: String {
        switch self {
        case .uthmani: return "Uthmani — Amiri Quran"
        case .indopak: return "IndoPak — Nastaleeq"
        case .system: return "Font Sistem"
        }
    }

    /// Nama PostScript untuk `NSFont`/`Font.custom`.
    public var postScriptName: String? {
        switch self {
        case .uthmani: return "AmiriQuran-Regular"
        case .indopak: return "AlQuran-IndoPak-by-QuranWBW"
        case .system: return nil
        }
    }

    /// Nama family (untuk diagnostik/fallback).
    public var familyName: String? {
        switch self {
        case .uthmani: return "Amiri Quran"
        case .indopak: return "AlQuran IndoPak by QuranWBW"
        case .system: return nil
        }
    }

    /// Nama berkas TTF di bundle (tanpa ekstensi), `nil` untuk font sistem.
    public var bundledFileName: String? {
        switch self {
        case .uthmani: return "AmiriQuran-Regular"
        case .indopak: return "IndoPakNastaleeq"
        case .system: return nil
        }
    }

    /// Jarak baris yang nyaman untuk masing-masing font.
    public var recommendedLineSpacing: Double {
        switch self {
        case .indopak: return 18   // Nastaleeq butuh ruang vertikal lebih besar
        case .uthmani: return 14
        case .system: return 10
        }
    }
}
