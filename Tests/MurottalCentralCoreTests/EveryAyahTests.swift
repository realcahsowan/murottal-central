import XCTest
@testable import MurottalCentralCore

final class EveryAyahTests: XCTestCase {

    func testFileNamePadsSurahAndAyah() {
        XCTAssertEqual(EveryAyah.fileName(surah: 1, ayah: 1), "001001.mp3")
        XCTAssertEqual(EveryAyah.fileName(surah: 4, ayah: 148), "004148.mp3")
        XCTAssertEqual(EveryAyah.fileName(surah: 114, ayah: 6), "114006.mp3")
    }

    func testAudioURL() {
        XCTAssertEqual(
            EveryAyah.audioURL(
                subfolder: "Abdul_Basit_Murattal_192kbps",
                surah: 4,
                ayah: 148
            ).absoluteString,
            "https://everyayah.com/data/Abdul_Basit_Murattal_192kbps/004148.mp3"
        )
    }

    func testAudioURLWithNestedSubfolder() {
        XCTAssertEqual(
            EveryAyah.audioURL(
                subfolder: "warsh/warsh_ibrahim_aldosary_128kbps",
                surah: 4,
                ayah: 148
            ).absoluteString,
            "https://everyayah.com/data/warsh/warsh_ibrahim_aldosary_128kbps/004148.mp3"
        )
    }

    func testAudioURLFromReciter() {
        let reciter = AyahReciter(
            id: 20,
            subfolder: "Husary_128kbps",
            name: "Mahmoud Khalil Al-Husary",
            bitrate: "128kbps"
        )
        XCTAssertEqual(
            EveryAyah.audioURL(reciter: reciter, surah: 5, ayah: 81).absoluteString,
            "https://everyayah.com/data/Husary_128kbps/005081.mp3"
        )
    }
}

final class QuranTextSanitizerTests: XCTestCase {

    func testRemovesTajweedTags() {
        let input = "وَ<tajweed class=ham_wasl>ٱ</tajweed>لنّ"
        let output = QuranTextSanitizer.plain(input)
        XCTAssertFalse(output.contains("<"))
        XCTAssertFalse(output.contains("tajweed"))
        XCTAssertTrue(output.contains("وَ"))
    }

    func testRemovesEndMarkerIncludingNumber() {
        let input = "ٱلْقَارِعَةُ <span class=end>١</span>"
        let output = QuranTextSanitizer.plain(input)
        XCTAssertFalse(output.contains("<"))
        XCTAssertFalse(output.contains("١"))
        XCTAssertEqual(output, "ٱلْقَارِعَةُ")
    }

    func testPlainTextUnchanged() {
        XCTAssertEqual(QuranTextSanitizer.plain("بِسْمِ ٱللَّهِ"), "بِسْمِ ٱللَّهِ")
    }

    func testCollapsesSpaces() {
        XCTAssertEqual(QuranTextSanitizer.plain("a   b\tc"), "a b c")
    }

    func testRemovesQuranComFootnotes() {
        let input = "Allah tidak menyukai perkataan buruk.<sup foot_note=135189>1</sup> Dan Allah Maha Mendengar."
        let output = QuranTextSanitizer.plain(input)

        XCTAssertEqual(output, "Allah tidak menyukai perkataan buruk. Dan Allah Maha Mendengar.")
        XCTAssertFalse(output.contains("sup"))
    }
}

final class AyahReciterSearchTests: XCTestCase {
    private let reciters = [
        AyahReciter(
            id: 2,
            subfolder: "Abdul_Basit_Murattal_192kbps",
            name: "Abdul Basit As-Samad (Murattal)",
            bitrate: "192kbps"
        ),
        AyahReciter(
            id: 20,
            subfolder: "Husary_128kbps",
            name: "Mahmoud Khalil Al-Husary",
            bitrate: "128kbps"
        ),
        AyahReciter(
            id: 60,
            subfolder: "warsh/warsh_ibrahim_aldosary_128kbps",
            name: "Ibrahim Al-Dosary (Warsh)",
            bitrate: "128kbps"
        ),
    ]

    func testEmptyQueryReturnsAll() {
        XCTAssertEqual(AyahReciterSearch.filter(reciters, query: "").count, 3)
        XCTAssertEqual(AyahReciterSearch.filter(reciters, query: "   ").count, 3)
    }

    func testFilterByName() {
        XCTAssertEqual(
            AyahReciterSearch.filter(reciters, query: "husary").map(\.id),
            [20]
        )
    }

    func testFilterBySubfolder() {
        XCTAssertEqual(
            AyahReciterSearch.filter(reciters, query: "warsh").map(\.id),
            [60]
        )
    }

    func testFilterByBitrate() {
        XCTAssertEqual(
            AyahReciterSearch.filter(reciters, query: "192").map(\.id),
            [2]
        )
    }

    func testCaseInsensitive() {
        XCTAssertEqual(
            AyahReciterSearch.filter(reciters, query: "BASIT").map(\.id),
            [2]
        )
    }

    func testNoMatchReturnsEmpty() {
        XCTAssertTrue(AyahReciterSearch.filter(reciters, query: "zzz").isEmpty)
    }
}

final class TranslationLanguageTests: XCTestCase {
    func testIndonesianUsesQuranComResource33() {
        XCTAssertEqual(TranslationLanguage.indonesian.quranComResourceID, 33)
    }

    func testEnglishDoesNotUseQuranCom() {
        XCTAssertNil(TranslationLanguage.english.quranComResourceID)
        XCTAssertNil(TranslationLanguage.none.quranComResourceID)
    }

    func testLabels() {
        XCTAssertEqual(TranslationLanguage.indonesian.shortLabel, "Indonesia")
        XCTAssertTrue(TranslationLanguage.indonesian.label.contains("Kemenag"))
        XCTAssertEqual(TranslationLanguage.none.shortLabel, "Off")
    }
}

final class AyahAudioTrackTests: XCTestCase {

    private let reciter = AyahReciter(
        id: 20,
        subfolder: "Husary_128kbps",
        name: "Mahmoud Khalil Al-Husary",
        bitrate: "128kbps"
    )

    func testAyahTrackHasAbsoluteURL() {
        let track = AudioTrack.ayah(surah: 4, ayah: 148, reciter: reciter)

        XCTAssertEqual(track.title, "004:148")
        XCTAssertTrue(track.isAbsoluteURL)
        XCTAssertEqual(
            track.streamURL.absoluteString,
            "https://everyayah.com/data/Husary_128kbps/004148.mp3"
        )
        XCTAssertNil(track.artworkIdentifier, "Audio per ayat tidak punya artwork katalog")
        XCTAssertEqual(track.fileName, "004148.mp3")
        XCTAssertEqual(track.downloadFolder, "ayah-everyayah")
    }

    func testRelativeTrackStillUsesPodcastBase() {
        let track = AudioTrack(title: "001", url: "mishary-rashid-alafasy/001.mp3")

        XCTAssertFalse(track.isAbsoluteURL)
        XCTAssertEqual(
            track.streamURL.absoluteString,
            "https://podcasts.qurancentral.com/mishary-rashid-alafasy/001.mp3"
        )
        XCTAssertEqual(track.artworkIdentifier, "mishary-rashid-alafasy")
        XCTAssertEqual(track.downloadFolder, "mishary-rashid-alafasy")
    }

    func testTrackCodableRoundTripKeepsArtworkSlug() throws {
        let original = AudioTrack(
            title: "001",
            duration: "52",
            url: "folder/001.mp3",
            artworkSlug: "some-reciter"
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(AudioTrack.self, from: data)

        XCTAssertEqual(decoded.artworkSlug, "some-reciter")
        XCTAssertEqual(decoded.url, "folder/001.mp3")
    }

    func testLegacyTrackWithoutArtworkSlugStillDecodes() throws {
        let json = Data(#"{"title":"001","url":"folder/001.mp3"}"#.utf8)
        let decoded = try JSONDecoder().decode(AudioTrack.self, from: json)

        XCTAssertNil(decoded.artworkSlug)
        XCTAssertEqual(decoded.url, "folder/001.mp3")
    }

    func testQuranVerseIdentifier() {
        let verse = QuranVerse(sura: 4, ayah: 148, text: "…")
        XCTAssertEqual(verse.id, "4:148")
    }
}
