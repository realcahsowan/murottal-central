import AppKit
import XCTest
@testable import MurottalCentralCore

final class QuranFontTests: XCTestCase {

    func testBundledFontsRegister() {
        let registered = QuranFontRegistry.registerBundledFonts()

        XCTAssertEqual(
            Set(registered),
            ["AmiriQuran-Regular", "IndoPakNastaleeq"]
        )
    }

    func testFontsAreAvailableAfterRegistration() {
        QuranFontRegistry.registerBundledFonts()

        XCTAssertTrue(QuranFontRegistry.isAvailable(.uthmani))
        XCTAssertTrue(QuranFontRegistry.isAvailable(.indopak))
        XCTAssertTrue(QuranFontRegistry.isAvailable(.system))
    }

    func testPostScriptNamesResolve() {
        QuranFontRegistry.registerBundledFonts()

        for font in [QuranFont.uthmani, .indopak] {
            let name = font.postScriptName
            XCTAssertNotNil(name)
            XCTAssertNotNil(
                NSFont(name: name!, size: 24),
                "Font \(name!) seharusnya bisa dimuat Core Text"
            )
        }
    }

    func testMetadata() {
        XCTAssertEqual(QuranFont.uthmani.familyName, "Amiri Quran")
        XCTAssertEqual(QuranFont.uthmani.postScriptName, "AmiriQuran-Regular")
        XCTAssertEqual(QuranFont.indopak.familyName, "AlQuran IndoPak by QuranWBW")
        XCTAssertNil(QuranFont.system.postScriptName)
        XCTAssertEqual(QuranFont.indopak.recommendedLineSpacing, 18)
        XCTAssertEqual(QuranFont.allCases.count, 3)
    }
}
