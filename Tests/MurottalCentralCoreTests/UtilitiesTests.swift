import XCTest
@testable import MurottalCentralCore

final class UtilitiesTests: XCTestCase {

    // MARK: - DurationParser

    func testDurationSecondsSingleValue() {
        XCTAssertEqual(DurationParser.seconds(from: "52"), 52)
        XCTAssertEqual(DurationParser.seconds(from: "0"), 0)
    }

    func testDurationSecondsMinutesSeconds() {
        XCTAssertEqual(DurationParser.seconds(from: "28:09"), 28 * 60 + 9)
        XCTAssertEqual(DurationParser.seconds(from: "01:00"), 60)
    }

    func testDurationSecondsHours() {
        XCTAssertEqual(DurationParser.seconds(from: "2:06:16"), 2 * 3600 + 6 * 60 + 16)
    }

    func testDurationInvalid() {
        XCTAssertNil(DurationParser.seconds(from: nil))
        XCTAssertNil(DurationParser.seconds(from: ""))
        XCTAssertNil(DurationParser.seconds(from: "abc"))
        XCTAssertNil(DurationParser.seconds(from: "1:2:3:4"))
    }

    func testDurationFormatting() {
        XCTAssertEqual(DurationParser.format(52), "0:52")
        XCTAssertEqual(DurationParser.format(28 * 60 + 9), "28:09")
        XCTAssertEqual(DurationParser.format(2 * 3600 + 6 * 60 + 16), "2:06:16")
        XCTAssertEqual(DurationParser.formatted(from: nil), "--:--")
    }

    // MARK: - ArtworkResolver

    func testArtworkAlias() {
        XCTAssertEqual(ArtworkResolver.artworkSlug(for: "abdul-basit"), "abdul-basit-abd-us-samad")
        XCTAssertEqual(ArtworkResolver.artworkSlug(for: "mishary-rashid-alafasy"), "mishary-rashid-alafasy")
    }

    func testFolderSlugFromAudioURL() {
        XCTAssertEqual(
            ArtworkResolver.folderSlug(fromAudioURL: "abdul-basit/001.mp3"),
            "abdul-basit-abd-us-samad"
        )
        XCTAssertEqual(
            ArtworkResolver.folderSlug(fromAudioURL: "mishary-rashid-alafasy/x.mp3"),
            "mishary-rashid-alafasy"
        )
    }

    // MARK: - Endpoints

    func testEndpointURLs() {
        XCTAssertEqual(
            QCEndpoints.reciters.absoluteString,
            "https://data.qurancentral.com/reciters.json"
        )
        XCTAssertEqual(
            QCEndpoints.category("mishary-rashid-alafasy").absoluteString,
            "https://data.qurancentral.com/categories/mishary-rashid-alafasy.json"
        )
        XCTAssertEqual(
            QCEndpoints.surahTag("001-al-fatiha").absoluteString,
            "https://data.qurancentral.com/tags/001-al-fatiha.json"
        )
        XCTAssertEqual(
            QCEndpoints.audioURL(for: "a/b.mp3").absoluteString,
            "https://podcasts.qurancentral.com/a/b.mp3"
        )
        XCTAssertEqual(
            QCEndpoints.artworkURL(for: "abdul-basit").absoluteString,
            "https://artwork.qurancentral.com/abdul-basit-abd-us-samad-300x300.jpg"
        )
    }
}
