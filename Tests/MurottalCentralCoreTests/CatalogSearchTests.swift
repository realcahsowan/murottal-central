import XCTest
@testable import MurottalCentralCore

final class CatalogSearchTests: XCTestCase {

    private let reciters: [Reciter] = [
        Reciter(id: 1, slug: "mishary-rashid-alafasy", name: "Mishary Rashid Alafasy",
                postCount: 114, country: "Kuwait", dialect: "Hafs"),
        Reciter(id: 2, slug: "abdur-rahman-as-sudais", name: "Abdur Rahman As-Sudais",
                postCount: 114, country: "Saudi Arabia", dialect: "Hafs"),
        Reciter(id: 3, slug: "abdelhamid-hssain", name: "Abdelhamid Hssain - Warsh",
                postCount: 114, country: "Morocco", dialect: "Warsh"),
        Reciter(id: 4, slug: "maryam-amir", name: "Maryam Amir",
                postCount: 2, country: "USA", dialect: "Hafs", female: true),
    ]

    private let surahs: [Surah] = [
        Surah(id: 1, transliteration: "Al Faatiha", arabic: "الفاتحة",
              translation: "The Opener", slug: "001-al-fatiha"),
        Surah(id: 2, transliteration: "Al Baqara", arabic: "البقرة",
              translation: "The Cow", slug: "002-al-baqara"),
        Surah(id: 114, transliteration: "An Naas", arabic: "الناس",
              translation: "Mankind", slug: "114-an-naas"),
    ]

    // MARK: Qari

    func testSearchRecitersByName() {
        let result = CatalogSearch.reciters(reciters, query: "alafasy")
        XCTAssertEqual(result.map(\.slug), ["mishary-rashid-alafasy"])
    }

    func testSearchRecitersCaseInsensitive() {
        XCTAssertEqual(CatalogSearch.reciters(reciters, query: "SUDAIS").count, 1)
    }

    func testSearchRecitersEmptyQueryReturnsAll() {
        XCTAssertEqual(CatalogSearch.reciters(reciters, query: "").count, 4)
        XCTAssertEqual(CatalogSearch.reciters(reciters, query: "   ").count, 4)
    }

    func testFilterRecitersByCountry() {
        let result = CatalogSearch.reciters(reciters, query: "", country: "Morocco")
        XCTAssertEqual(result.map(\.slug), ["abdelhamid-hssain"])
    }

    func testFilterRecitersByDialect() {
        let result = CatalogSearch.reciters(reciters, query: "", dialect: "Warsh")
        XCTAssertEqual(result.map(\.slug), ["abdelhamid-hssain"])
    }

    func testFilterRecitersCombined() {
        let result = CatalogSearch.reciters(reciters, query: "a", country: "Kuwait", dialect: "Hafs")
        XCTAssertEqual(result.map(\.slug), ["mishary-rashid-alafasy"])
    }

    func testCountriesAndDialects() {
        XCTAssertEqual(
            CatalogSearch.countries(in: reciters),
            ["Kuwait", "Morocco", "Saudi Arabia", "USA"]
        )
        XCTAssertEqual(CatalogSearch.dialects(in: reciters), ["Hafs", "Warsh"])
    }

    // MARK: Surah

    func testSearchSurahsByName() {
        XCTAssertEqual(CatalogSearch.surahs(surahs, query: "baqara").map(\.id), [2])
    }

    func testSearchSurahsByNumber() {
        XCTAssertEqual(CatalogSearch.surahs(surahs, query: "114").map(\.id), [114])
        XCTAssertEqual(CatalogSearch.surahs(surahs, query: "002").map(\.id), [2])
    }

    func testSearchSurahsByArabic() {
        XCTAssertEqual(CatalogSearch.surahs(surahs, query: "الناس").map(\.id), [114])
    }

    func testSearchSurahsByTranslation() {
        XCTAssertEqual(CatalogSearch.surahs(surahs, query: "cow").map(\.id), [2])
    }

    func testSearchSurahsEmptyReturnsAll() {
        XCTAssertEqual(CatalogSearch.surahs(surahs, query: "").count, 3)
    }

    // MARK: Trek

    func testSearchTracksInPlaylist() {
        let tracks = [
            AudioTrack(title: "001 Al-Fatiha", url: "qari/001.mp3"),
            AudioTrack(title: "002 Al-Baqara", url: "qari/002.mp3"),
            AudioTrack(title: "114 An-Nas", url: "qari/114.mp3"),
        ]

        XCTAssertEqual(CatalogSearch.tracks(tracks, query: "baqara").map(\.title), ["002 Al-Baqara"])
        XCTAssertEqual(CatalogSearch.tracks(tracks, query: "001").count, 1)
        XCTAssertEqual(CatalogSearch.tracks(tracks, query: "").count, 3)
        XCTAssertTrue(CatalogSearch.tracks(tracks, query: "zzz").isEmpty)
    }

    func testSearchTracksMatchesFileName() {
        let tracks = [AudioTrack(title: "Track", url: "qari/special-recording.mp3")]
        XCTAssertEqual(CatalogSearch.tracks(tracks, query: "special").count, 1)
    }
}
