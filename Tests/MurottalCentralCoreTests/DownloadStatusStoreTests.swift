import XCTest
@testable import MurottalCentralCore

@MainActor
final class DownloadStatusStoreTests: XCTestCase {

    func testDefaultStateIsNotDownloaded() {
        let store = DownloadStatusStore()
        XCTAssertEqual(store.state(for: "a.mp3"), .notDownloaded)
    }

    func testProgressReporting() {
        let store = DownloadStatusStore()
        store.set(.downloading(progress: 0.25), for: "a.mp3")

        XCTAssertEqual(store.state(for: "a.mp3"), .downloading(progress: 0.25))
        XCTAssertEqual(store.state(for: "a.mp3").progress, 0.25)
        XCTAssertTrue(store.state(for: "a.mp3").isDownloading)
        XCTAssertFalse(store.state(for: "a.mp3").isIndeterminate)
    }

    func testIndeterminateProgress() {
        let store = DownloadStatusStore()
        store.set(.downloading(progress: -1), for: "a.mp3")

        XCTAssertNil(store.state(for: "a.mp3").progress)
        XCTAssertTrue(store.state(for: "a.mp3").isIndeterminate)
        XCTAssertTrue(store.state(for: "a.mp3").isDownloading)
    }

    func testCompletedAndFailed() {
        let store = DownloadStatusStore()
        store.set(.downloaded, for: "a.mp3")
        store.set(.failed("boom"), for: "b.mp3")

        XCTAssertTrue(store.state(for: "a.mp3").isDownloaded)
        XCTAssertEqual(store.state(for: "b.mp3"), .failed("boom"))
    }

    func testActiveDownloadsListsOnlyDownloading() {
        let store = DownloadStatusStore()
        store.set(.downloading(progress: 0.1), for: "b.mp3")
        store.set(.downloading(progress: 0.9), for: "a.mp3")
        store.set(.downloaded, for: "c.mp3")

        XCTAssertEqual(store.activeDownloads.map(\.key), ["a.mp3", "b.mp3"])
    }

    func testPausedState() {
        let store = DownloadStatusStore()
        store.set(.paused(progress: 0.42), for: "a.mp3")

        let state = store.state(for: "a.mp3")
        XCTAssertTrue(state.isPaused)
        XCTAssertFalse(state.isDownloading)
        XCTAssertTrue(state.isActive)
        XCTAssertEqual(state.progress, 0.42)
    }

    func testPausedIncludedInActiveDownloads() {
        let store = DownloadStatusStore()
        store.set(.paused(progress: 0.5), for: "a.mp3")
        store.set(.downloading(progress: 0.5), for: "b.mp3")
        store.set(.downloaded, for: "c.mp3")

        XCTAssertEqual(store.activeDownloads.map(\.key), ["a.mp3", "b.mp3"])
    }

    func testSettingNotDownloadedRemovesEntry() {
        let store = DownloadStatusStore()
        store.set(.downloaded, for: "a.mp3")
        store.set(.notDownloaded, for: "a.mp3")
        XCTAssertTrue(store.states.isEmpty)
    }

    func testRemoveAll() {
        let store = DownloadStatusStore()
        store.set(.downloaded, for: "a.mp3")
        store.removeAll()
        XCTAssertTrue(store.states.isEmpty)
    }
}
