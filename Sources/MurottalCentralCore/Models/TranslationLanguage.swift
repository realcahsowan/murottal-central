import Foundation

/// Bahasa terjemahan yang tersedia di layar baca.
public enum TranslationLanguage: String, CaseIterable, Identifiable, Sendable {
    case none
    case english
    case indonesian

    public var id: String { rawValue }

    /// Label lengkap untuk menu/pengaturan.
    public var label: String {
        switch self {
        case .none: return "Tanpa terjemahan"
        case .english: return "English — Sahih International"
        case .indonesian: return "Bahasa Indonesia — Kemenag"
        }
    }

    /// Label ringkas untuk toolbar.
    public var shortLabel: String {
        switch self {
        case .none: return "Off"
        case .english: return "English"
        case .indonesian: return "Indonesia"
        }
    }

    /// ID resource di Quran.com (hanya untuk bahasa yang diambil dari sana).
    ///
    /// - `33` = Indonesian Islamic Affairs Ministry (Kemenag)
    public var quranComResourceID: Int? {
        switch self {
        case .none, .english: return nil   // English tetap dari Quran Central
        case .indonesian: return 33
        }
    }
}
