import XCTest
@testable import MurottalCentralCore

@MainActor
final class AudioPlayerSleepTimerTests: XCTestCase {

    func testPresetsArePositiveAndSorted() {
        let presets = AudioPlayer.sleepTimerPresets
        XCTAssertFalse(presets.isEmpty)
        XCTAssertEqual(presets, presets.sorted())
        XCTAssertTrue(presets.allSatisfy { $0 > 0 })
    }

    func testInitiallyOff() {
        let player = AudioPlayer(defaults: UserDefaults(suiteName: UUID().uuidString)!)
        XCTAssertEqual(player.sleepTimerMode, .off)
        XCTAssertNil(player.sleepTimerRemaining)
        XCTAssertFalse(player.sleepTimerMode.isActive)
    }

    func testSetSleepTimerMinutes() {
        let player = AudioPlayer(defaults: UserDefaults(suiteName: UUID().uuidString)!)
        player.setSleepTimer(minutes: 5)

        XCTAssertEqual(player.sleepTimerMode, .duration(300))
        let remaining = try? XCTUnwrap(player.sleepTimerRemaining)
        XCTAssertEqual(remaining ?? 0, 300, accuracy: 1)
    }

    func testSetSleepTimerEndOfTrack() {
        let player = AudioPlayer(defaults: UserDefaults(suiteName: UUID().uuidString)!)
        player.setSleepTimerEndOfTrack()

        XCTAssertEqual(player.sleepTimerMode, .endOfTrack)
        XCTAssertNil(player.sleepTimerRemaining)
        XCTAssertTrue(player.sleepTimerMode.isActive)
    }

    func testCancelSleepTimer() {
        let player = AudioPlayer(defaults: UserDefaults(suiteName: UUID().uuidString)!)
        player.setSleepTimer(minutes: 10)
        player.cancelSleepTimer()

        XCTAssertEqual(player.sleepTimerMode, .off)
        XCTAssertNil(player.sleepTimerRemaining)
    }

    func testZeroDurationCancels() {
        let player = AudioPlayer(defaults: UserDefaults(suiteName: UUID().uuidString)!)
        player.setSleepTimer(minutes: 5)
        player.setSleepTimer(duration: 0)

        XCTAssertEqual(player.sleepTimerMode, .off)
    }

    func testCountdownExpires() async throws {
        let player = AudioPlayer(defaults: UserDefaults(suiteName: UUID().uuidString)!)
        player.setSleepTimer(duration: 0.5)

        XCTAssertTrue(player.sleepTimerMode.isActive)

        try await Task.sleep(for: .milliseconds(1200))

        XCTAssertEqual(player.sleepTimerMode, .off)
        XCTAssertNil(player.sleepTimerRemaining)
    }

    func testSwitchingModeReplacesPrevious() {
        let player = AudioPlayer(defaults: UserDefaults(suiteName: UUID().uuidString)!)
        player.setSleepTimer(minutes: 30)
        player.setSleepTimerEndOfTrack()

        XCTAssertEqual(player.sleepTimerMode, .endOfTrack)
        XCTAssertNil(player.sleepTimerRemaining)
    }
}
