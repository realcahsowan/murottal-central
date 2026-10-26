import XCTest
@testable import MurottalCentralCore

@MainActor
final class AppSettingsTests: XCTestCase {

    private func makeDefaults() -> UserDefaults {
        UserDefaults(suiteName: "murottal.tests.\(UUID().uuidString)")!
    }

    func testDefaults() {
        let settings = AppSettings(defaults: makeDefaults())
        XCTAssertEqual(settings.theme, .system)
        XCTAssertFalse(settings.hideFemalePhotos)
        XCTAssertFalse(settings.hideMalePhotos)
        XCTAssertTrue(settings.showArtworkBadges)
    }

    func testPersistenceAcrossInstances() {
        let defaults = makeDefaults()

        let first = AppSettings(defaults: defaults)
        first.theme = .dark
        first.hideFemalePhotos = true
        first.showArtworkBadges = false

        let second = AppSettings(defaults: defaults)
        XCTAssertEqual(second.theme, .dark)
        XCTAssertTrue(second.hideFemalePhotos)
        XCTAssertFalse(second.showArtworkBadges)
    }

    func testShouldHideArtwork() {
        let settings = AppSettings(defaults: makeDefaults())
        XCTAssertFalse(settings.shouldHideArtwork(isFemale: true))
        XCTAssertFalse(settings.shouldHideArtwork(isFemale: false))

        settings.hideFemalePhotos = true
        XCTAssertTrue(settings.shouldHideArtwork(isFemale: true))
        XCTAssertFalse(settings.shouldHideArtwork(isFemale: false))

        settings.hideMalePhotos = true
        XCTAssertTrue(settings.shouldHideArtwork(isFemale: false))
    }

    func testReset() {
        let settings = AppSettings(defaults: makeDefaults())
        settings.theme = .light
        settings.hideMalePhotos = true
        settings.showArtworkBadges = false

        settings.reset()

        XCTAssertEqual(settings.theme, .system)
        XCTAssertFalse(settings.hideMalePhotos)
        XCTAssertTrue(settings.showArtworkBadges)
    }

    func testThemeLabels() {
        XCTAssertEqual(AppSettings.Theme.allCases.count, 3)
        XCTAssertEqual(AppSettings.Theme.dark.label, "Gelap")
    }

    func testTranslationLanguageDefaultAndPersistence() {
        let defaults = makeDefaults()

        let first = AppSettings(defaults: defaults)
        XCTAssertEqual(first.translationLanguage, .english)

        first.translationLanguage = .indonesian

        let second = AppSettings(defaults: defaults)
        XCTAssertEqual(second.translationLanguage, .indonesian)
    }

    func testResetRestoresTranslationLanguage() {
        let settings = AppSettings(defaults: makeDefaults())
        settings.translationLanguage = .none
        settings.reset()
        XCTAssertEqual(settings.translationLanguage, .english)
    }

    func testQuranFontDefaultsAndPersistence() {
        let defaults = makeDefaults()

        let first = AppSettings(defaults: defaults)
        XCTAssertEqual(first.quranFont, .uthmani)
        XCTAssertEqual(first.arabicFontSize, 26, accuracy: 0.001)

        first.quranFont = .indopak
        first.arabicFontSize = 34

        let second = AppSettings(defaults: defaults)
        XCTAssertEqual(second.quranFont, .indopak)
        XCTAssertEqual(second.arabicFontSize, 34, accuracy: 0.001)
    }

    func testResetRestoresQuranFont() {
        let settings = AppSettings(defaults: makeDefaults())
        settings.quranFont = .system
        settings.arabicFontSize = 40
        settings.reset()

        XCTAssertEqual(settings.quranFont, .uthmani)
        XCTAssertEqual(settings.arabicFontSize, 26, accuracy: 0.001)
    }
}
