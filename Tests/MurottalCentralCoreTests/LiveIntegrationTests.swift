import XCTest
@testable import MurottalCentralCore

/// Tes integrasi yang memanggil API Quran Central secara nyata.
///
/// Dinonaktifkan secara default agar `swift test` tetap offline & cepat.
/// Jalankan dengan:
///
/// ```bash
/// MUROTTAL_LIVE=1 swift test --filter LiveIntegrationTests
/// ```
final class LiveIntegrationTests: XCTestCase {

    private var isEnabled: Bool {
        ProcessInfo.processInfo.environment["MUROTTAL_LIVE"] == "1"
    }

    override func setUpWithError() throws {
        try XCTSkipUnless(isEnabled, "Set MUROTTAL_LIVE=1 untuk menjalankan tes live.")
    }

    func testFetchCatalog() async throws {
        let client = QuranCentralClient()
        let reciters = try await client.reciters()
        let surahs = try await client.surahs()

        XCTAssertEqual(surahs.count, 114)
        XCTAssertGreaterThan(reciters.count, 500)
        XCTAssertTrue(reciters.contains { $0.slug == "mishary-rashid-alafasy" })
    }

    func testFetchAlafasyCategory() async throws {
        let client = QuranCentralClient()
        let category = try await client.category(slug: "mishary-rashid-alafasy")

        XCTAssertEqual(category.title, "Mishary Rashid Alafasy")
        XCTAssertEqual(category.items.count, 114)
        XCTAssertEqual(category.items.first?.durationSeconds, 52)
    }

    func testFetchSurahTag() async throws {
        let client = QuranCentralClient()
        let tag = try await client.surahTag(slug: "001-al-fatiha")
        XCTAssertGreaterThan(tag.items.count, 100)
    }

    func testAudioIsReachable() async throws {        let url = QCEndpoints.audioURL(
            for: "mishary-rashid-alafasy/mishary-rashid-alafasy-001-muslimcentral.com.mp3"
        )
        var request = URLRequest(url: url)
        request.setValue("MurottalCentral/0.1 (macOS)", forHTTPHeaderField: "User-Agent")
        request.setValue("bytes=0-1023", forHTTPHeaderField: "Range")

        let (data, response) = try await URLSession.shared.data(for: request)
        let http = try XCTUnwrap(response as? HTTPURLResponse)
        XCTAssertEqual(http.statusCode, 206)
        XCTAssertEqual(data.count, 1024)
    }

    @MainActor
    func testDownloadWithProgress() async throws {
        let status = DownloadStatusStore()
        let root = FileManager.default.temporaryDirectory
            .appending(path: "murottal-test-\(UUID().uuidString)")
        let manager = DownloadManager(root: root, status: status)

        let track = AudioTrack(
            title: "001 Al-Fatiha",
            duration: "52",
            url: "mishary-rashid-alafasy/mishary-rashid-alafasy-001-muslimcentral.com.mp3"
        )

        let localURL = try await manager.download(track)
        XCTAssertTrue(FileManager.default.fileExists(atPath: localURL.path))
        XCTAssertEqual(status.state(for: track.url), .downloaded)

        let map = await manager.localURLMap()
        XCTAssertEqual(map[track.url], localURL)

        let size = await manager.totalSize()
        XCTAssertGreaterThan(size, 0)

        try await manager.deleteAll()
        XCTAssertFalse(FileManager.default.fileExists(atPath: localURL.path))
    }

    @MainActor
    func testPauseAndResumeDownload() async throws {
        let status = DownloadStatusStore()
        let root = FileManager.default.temporaryDirectory
            .appending(path: "murottal-resume-\(UUID().uuidString)")
        let manager = DownloadManager(root: root, status: status)

        let track = AudioTrack(
            title: "001 Al-Fatiha",
            duration: "52",
            url: "mishary-rashid-alafasy/mishary-rashid-alafasy-001-muslimcentral.com.mp3"
        )

        let canResumeInitially = await manager.canResume(track)
        XCTAssertFalse(canResumeInitially)

        let task = Task { try await manager.download(track) }
        try await Task.sleep(for: .milliseconds(60))
        await manager.pause(track)

        var wasPaused = false
        do {
            _ = try await task.value
        } catch DownloadManager.DownloadError.paused {
            wasPaused = true
        }

        let hasResumeData = await manager.canResume(track)
        if wasPaused, hasResumeData {
            let state = status.state(for: track.url)
            XCTAssertTrue(state.isPaused || state.isDownloading)
        }

        // Lanjutkan (atau mulai ulang bila resume data tidak tersedia).
        let localURL = try await manager.download(track)
        XCTAssertTrue(FileManager.default.fileExists(atPath: localURL.path))
        XCTAssertEqual(status.state(for: track.url), .downloaded)

        try await manager.deleteAll()
    }

    /// Regresi end-to-end: memutar trek memicu `loadArtwork` +
    /// `refreshNowPlaying`. Sebelum perbaikan, MediaPlayer memanggil handler
    /// artwork dari queue internalnya dan aplikasi crash (SIGILL).
    @MainActor
    func testPlayingPublishesNowPlayingWithoutCrash() async throws {
        let player = AudioPlayer(defaults: UserDefaults(suiteName: UUID().uuidString)!)

        let track = AudioTrack(
            title: "001 Al-Fatiha",
            duration: "52",
            url: "mishary-rashid-alafasy/mishary-rashid-alafasy-001-muslimcentral.com.mp3"
        )

        player.play([track], startingAt: 0)
        XCTAssertEqual(player.current?.url, track.url)
        XCTAssertTrue(player.isPlaying)

        // Beri waktu artwork terunduh dan Now Playing dipublikasikan ke sistem.
        try await Task.sleep(for: .seconds(4))

        XCTAssertEqual(player.current?.url, track.url)
        player.stop()
    }

    // MARK: - Fitur baca (teks & audio per ayat)

    func testFetchAyahReciters() async throws {
        let client = QuranCentralClient()
        let reciters = try await client.ayahReciters()

        XCTAssertEqual(reciters.count, 45)
        XCTAssertTrue(reciters.contains { $0.subfolder == "Husary_128kbps" })
        XCTAssertTrue(reciters.contains { $0.subfolder.hasPrefix("warsh/") })
        XCTAssertEqual(reciters.map(\.id), reciters.map(\.id).sorted())
    }

    func testFetchQuranText() async throws {
        let client = QuranCentralClient()
        let arabic = try await client.quranUthmani()
        let english = try await client.quranEnglish()

        XCTAssertEqual(arabic.count, 6236)
        XCTAssertEqual(english.count, 6236)

        let verse = try XCTUnwrap(arabic.first { $0.sura == 4 && $0.ayah == 148 })
        XCTAssertEqual(verse.id, "4:148")

        let cleaned = QuranTextSanitizer.plain(verse.text)
        XCTAssertFalse(cleaned.isEmpty)
        XCTAssertFalse(cleaned.contains("<"))

        let translation = try XCTUnwrap(english.first { $0.sura == 4 && $0.ayah == 148 })
        XCTAssertFalse(translation.text.isEmpty)
    }

    /// Regresi: teks Uthmani harus memakai U+0670 (superscript alef) agar alif
    /// madd tampil benar dengan font KFGQPC, bukan U+0672 (yang dipetakan ke
    /// glyph "number sign" berbentuk bulatan).
    func testUthmaniUsesSuperscriptAlefNotWavyHamza() async throws {
        let client = QuranCentralClient()
        let uthmani = try await client.quranUthmani()

        func scalars(_ text: String) -> Set<UInt32> {
            Set(text.unicodeScalars.map(\.value))
        }

        let verse = try XCTUnwrap(uthmani.first { $0.sura == 67 && $0.ayah == 2 })
        XCTAssertTrue(scalars(verse.text).contains(0x0670))
        XCTAssertFalse(scalars(verse.text).contains(0x0672))

        let third = try XCTUnwrap(uthmani.first { $0.sura == 67 && $0.ayah == 3 })
        XCTAssertTrue(scalars(third.text).contains(0x0670))
        XCTAssertFalse(scalars(third.text).contains(0x0672))
    }

    func testFetchIndopakText() async throws {
        let client = QuranCentralClient()
        let indopak = try await client.quranIndopak()

        XCTAssertEqual(indopak.count, 6236)
        XCTAssertEqual(indopak.first?.id, "1:1")
        XCTAssertEqual(indopak.last?.id, "114:6")
    }

    func testAyahAudioIsReachable() async throws {
        let url = EveryAyah.audioURL(
            subfolder: "Husary_128kbps",
            surah: 4,
            ayah: 148
        )

        var request = URLRequest(url: url)
        request.setValue("MurottalCentral/0.1 (macOS)", forHTTPHeaderField: "User-Agent")
        request.setValue("bytes=0-1023", forHTTPHeaderField: "Range")

        let (data, response) = try await URLSession.shared.data(for: request)
        let http = try XCTUnwrap(response as? HTTPURLResponse)

        XCTAssertEqual(http.statusCode, 206)
        XCTAssertEqual(data.count, 1024)
    }

    /// Juz 6 = 4:148–5:81 → 110 ayat.
    func testJuzSixVerseCount() async throws {        let client = QuranCentralClient()
        let arabic = try await client.quranUthmani()
        let juzList = try await client.juzList()
        let juz = try XCTUnwrap(juzList.first { $0.index == 6 })

        let verses = arabic.filter { verse in
            let start = juz.start
            let end = juz.end
            if start.surah == end.surah {
                return verse.sura == start.surah
                    && verse.ayah >= start.verse
                    && verse.ayah <= end.verse
            }
            if verse.sura == start.surah { return verse.ayah >= start.verse }
            if verse.sura == end.surah { return verse.ayah <= end.verse }
            return verse.sura > start.surah && verse.sura < end.surah
        }

        XCTAssertEqual(verses.count, 110)
        XCTAssertEqual(verses.first?.id, "4:148")
        XCTAssertEqual(verses.last?.id, "5:81")
    }

    // MARK: - Terjemahan Indonesia (Quran.com)

    func testFetchIndonesianTranslation() async throws {
        let client = QuranCentralClient()
        let texts = try await client.quranTranslation(resourceID: 33)

        XCTAssertEqual(texts.count, 6236)
        XCTAssertTrue(texts[0].contains("Maha Pengasih"))
        // Indeks 640 = 4:148 (7 + 286 + 200 ayat sebelumnya + 147)
        XCTAssertTrue(texts[640].contains("Allah tidak menyukai"))
    }

    func testIndonesianTranslationMapsToArabicVerses() async throws {
        let client = QuranCentralClient()
        let arabic = try await client.quranUthmani()
        let texts = try await client.quranTranslation(resourceID: 33)

        XCTAssertEqual(arabic.count, texts.count)

        let index = try XCTUnwrap(arabic.firstIndex { $0.sura == 4 && $0.ayah == 148 })
        let cleaned = QuranTextSanitizer.plain(texts[index])

        XCTAssertTrue(cleaned.contains("Allah tidak menyukai"))
        XCTAssertFalse(cleaned.contains("sup"))
    }

    /// Memutar satu ayat dari EveryAyah lewat `AudioPlayer`.
    @MainActor
    func testPlayAyahTrack() async throws {
        let player = AudioPlayer(defaults: UserDefaults(suiteName: UUID().uuidString)!)
        let reciter = AyahReciter(
            id: 20,
            subfolder: "Husary_128kbps",
            name: "Mahmoud Khalil Al-Husary",
            bitrate: "128kbps"
        )
        let track = AudioTrack.ayah(surah: 4, ayah: 148, reciter: reciter)

        player.play([track], startingAt: 0)
        XCTAssertEqual(player.current?.title, "004:148")
        XCTAssertTrue(player.isPlaying)

        try await Task.sleep(for: .seconds(4))

        XCTAssertEqual(player.current?.url, track.url)
        player.stop()
    }
}
