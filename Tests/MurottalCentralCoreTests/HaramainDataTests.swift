import XCTest
@testable import MurottalCentralCore

final class HaramainDataTests: XCTestCase {

    func testGroups() {
        XCTAssertEqual(HaramainData.groups.map(\.id), ["makkah", "madinah"])
        XCTAssertEqual(HaramainData.groups[0].reciters.count, 14)
        XCTAssertEqual(HaramainData.groups[1].reciters.count, 12)
    }

    func testAllSlugsAreUnique() {
        let slugs = HaramainData.groups.flatMap { $0.reciters.map(\.slug) }
        XCTAssertEqual(slugs.count, Set(slugs).count)
    }

    func testKnownRecitersPresent() {
        let slugs = Set(HaramainData.groups.flatMap { $0.reciters.map(\.slug) })
        XCTAssertTrue(slugs.contains("maher-al-mueaqly"))
        XCTAssertTrue(slugs.contains("abdur-rahman-as-sudais"))
        XCTAssertTrue(slugs.contains("ali-abdur-rahman-al-huthaify"))
        XCTAssertTrue(slugs.contains("salah-al-budair"))
    }
}

final class JuzModelTests: XCTestCase {

    func testJuzSurahRange() {
        let juz = Juz(
            index: 1,
            start: VerseRef(surah: 1, verse: 1),
            end: VerseRef(surah: 2, verse: 141)
        )
        XCTAssertEqual(juz.id, 1)
        XCTAssertEqual(juz.start.surah, 1)
        XCTAssertEqual(juz.end.surah, 2)
    }
}
