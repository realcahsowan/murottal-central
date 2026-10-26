import Foundation
import Observation

/// Preferensi pengguna yang dipersist di `UserDefaults`.
@MainActor
@Observable
public final class AppSettings {

    public enum Theme: String, CaseIterable, Identifiable, Sendable {
        case system, light, dark

        public var id: String { rawValue }

        public var label: String {
            switch self {
            case .system: return "Ikuti Sistem"
            case .light: return "Terang"
            case .dark: return "Gelap"
            }
        }
    }

    private enum Key {
        static let theme = "murottal.settings.theme"
        static let hideFemalePhotos = "murottal.settings.hideFemalePhotos"
        static let hideMalePhotos = "murottal.settings.hideMalePhotos"
        static let showArtworkBadges = "murottal.settings.showArtworkBadges"
        static let translationLanguage = "murottal.settings.translationLanguage"
        static let quranFont = "murottal.settings.quranFont"
        static let arabicFontSize = "murottal.settings.arabicFontSize"
    }

    private let defaults: UserDefaults

    public var theme: Theme {
        didSet { defaults.set(theme.rawValue, forKey: Key.theme) }
    }

    /// Sembunyikan foto qari perempuan (memakai artwork fallback).
    public var hideFemalePhotos: Bool {
        didSet { defaults.set(hideFemalePhotos, forKey: Key.hideFemalePhotos) }
    }

    /// Sembunyikan foto qari laki-laki (memakai artwork fallback).
    public var hideMalePhotos: Bool {
        didSet { defaults.set(hideMalePhotos, forKey: Key.hideMalePhotos) }
    }

    /// Tampilkan badge gaya (mis. "Mujawwad") pada kartu qari.
    public var showArtworkBadges: Bool {
        didSet { defaults.set(showArtworkBadges, forKey: Key.showArtworkBadges) }
    }

    /// Bahasa terjemahan di layar baca.
    public var translationLanguage: TranslationLanguage {
        didSet {
            defaults.set(translationLanguage.rawValue, forKey: Key.translationLanguage)
        }
    }

    /// Font teks Arab di layar baca.
    public var quranFont: QuranFont {
        didSet { defaults.set(quranFont.rawValue, forKey: Key.quranFont) }
    }

    /// Ukuran font Arab (pt).
    public var arabicFontSize: Double {
        didSet { defaults.set(arabicFontSize, forKey: Key.arabicFontSize) }
    }

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.theme = Theme(rawValue: defaults.string(forKey: Key.theme) ?? "") ?? .system
        self.hideFemalePhotos = defaults.bool(forKey: Key.hideFemalePhotos)
        self.hideMalePhotos = defaults.bool(forKey: Key.hideMalePhotos)
        self.showArtworkBadges = defaults.object(forKey: Key.showArtworkBadges) as? Bool ?? true
        self.translationLanguage = TranslationLanguage(
            rawValue: defaults.string(forKey: Key.translationLanguage) ?? ""
        ) ?? .english
        self.quranFont = QuranFont(
            rawValue: defaults.string(forKey: Key.quranFont) ?? ""
        ) ?? .uthmani
        let storedSize = defaults.double(forKey: Key.arabicFontSize)
        self.arabicFontSize = storedSize > 0 ? storedSize : 26
    }

    /// Apakah artwork asli harus disembunyikan untuk qari dengan gender tertentu?
    public func shouldHideArtwork(isFemale: Bool) -> Bool {
        isFemale ? hideFemalePhotos : hideMalePhotos
    }

    public func reset() {
        theme = .system
        hideFemalePhotos = false
        hideMalePhotos = false
        showArtworkBadges = true
        translationLanguage = .english
        quranFont = .uthmani
        arabicFontSize = 26
    }
}
