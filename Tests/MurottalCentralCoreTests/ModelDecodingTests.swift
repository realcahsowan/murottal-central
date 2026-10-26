import XCTest
@testable import MurottalCentralCore

final class ModelDecodingTests: XCTestCase {

    private func fixture(_ name: String) throws -> Data {
        let url = try XCTUnwrap(
            Bundle.module.url(forResource: name, withExtension: "json"),
            "Fixture \(name).json tidak ditemukan"
        )
        return try Data(contentsOf: url)
    }

    private func decode<T: Decodable>(_ type: T.Type, from fixtureName: String) throws -> T {
        try JSONDecoder().decode(T.self, from: fixture(fixtureName))
    }

    // MARK: - Reciter

    func testDecodeReciters() throws {
        let reciters = try decode([Reciter].self, from: "reciters")
        XCTAssertEqual(reciters.count, 4)

        let first = try XCTUnwrap(reciters.first)
        XCTAssertEqual(first.slug, "aaar-al-hudhoudi")
        XCTAssertEqual(first.postCount, 111)
        XCTAssertEqual(first.countryLabel, "Saudi Arabia")
        XCTAssertTrue(first.hasAudio)

        let female = try XCTUnwrap(reciters.first { $0.slug == "maryam-amir" })
        XCTAssertEqual(female.female, true)
        XCTAssertEqual(female.postCount, 2)
    }

    // MARK: - Surah

    func testDecodeSurahs() throws {
        let surahs = try decode([Surah].self, from: "surahs")
        let first = try XCTUnwrap(surahs.first)
        XCTAssertEqual(first.id, 1)
        XCTAssertEqual(first.transliteration, "Al Faatiha")
        XCTAssertEqual(first.arabic, "الفاتحة")
        XCTAssertEqual(first.translation, "The Opener")
        XCTAssertEqual(first.slug, "001-al-fatiha")
        XCTAssertEqual(first.displayTitle, "001 — Al Faatiha")
    }

    // MARK: - Category

    func testDecodeCategory() throws {
        let category = try decode(ReciterCategory.self, from: "category")
        XCTAssertEqual(category.title, "Mishary Rashid Alafasy")
        XCTAssertEqual(category.items.count, 3)

        let track = try XCTUnwrap(category.items.first)
        XCTAssertEqual(track.duration, "52")
        XCTAssertEqual(track.durationSeconds, 52)
        XCTAssertEqual(track.reciterFolderSlug, "mishary-rashid-alafasy")
        XCTAssertEqual(
            track.streamURL.absoluteString,
            "https://podcasts.qurancentral.com/mishary-rashid-alafasy/mishary-rashid-alafasy-001-muslimcentral.com.mp3"
        )
    }

    // MARK: - Juz

    func testDecodeJuz() throws {
        let juz = try decode([Juz].self, from: "juz")
        XCTAssertEqual(juz.count, 3)
        XCTAssertEqual(juz[0].index, 1)
        XCTAssertEqual(juz[0].start.surah, 1)
        XCTAssertEqual(juz[0].end.verse, 141)
    }

    // MARK: - Surah tag

    func testDecodeSurahTag() throws {
        let tag = try decode(SurahTag.self, from: "surah-tag")
        XCTAssertEqual(tag.items.count, 3)
        XCTAssertEqual(tag.items[0].title, "Ahmed Abdelrazek Nasr")
        XCTAssertEqual(tag.items[0].durationSeconds, 28 * 60 + 9)
    }

    // MARK: - Toleransi data

    func testNullURLIsTolerated() throws {
        let json = Data("""
        {
          "title": "001 Al-Fatiha",
          "items": [
            { "duration": "56", "title": "Qari A", "url": null },
            { "duration": "56", "title": "Qari B", "url": "qari-b/001.mp3" }
          ]
        }
        """.utf8)

        let tag = try JSONDecoder().decode(SurahTag.self, from: json)
        XCTAssertEqual(tag.items.count, 2)
        XCTAssertFalse(tag.items[0].isPlayable)
        XCTAssertEqual(tag.items[0].url, "")
        XCTAssertTrue(tag.items[1].isPlayable)
    }

    func testPlayableTracksFiltersNullAndDonations() {
        let items = [
            AudioTrack(title: "OK", url: "qari/001.mp3"),
            AudioTrack(title: "Null", url: ""),
            AudioTrack(
                title: "Donasi",
                url: "muslim-central-mufti-menk-donation-appeal.mp3"
            ),
        ]
        let filtered = QuranCentralClient.playableTracks(items)
        XCTAssertEqual(filtered.count, 1)
        XCTAssertEqual(filtered.first?.title, "OK")
    }
}
