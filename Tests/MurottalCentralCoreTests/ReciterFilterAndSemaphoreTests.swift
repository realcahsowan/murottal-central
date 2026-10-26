import XCTest
@testable import MurottalCentralCore

final class ReciterFilterTests: XCTestCase {

    private let reciters: [Reciter] = [
        Reciter(id: 1, slug: "male-a", name: "Male A", postCount: 10, female: false),
        Reciter(id: 2, slug: "female-b", name: "Female B", postCount: 10, female: true),
        Reciter(id: 3, slug: "unknown-c", name: "Unknown C", postCount: 10, female: nil),
        Reciter(id: 4, slug: "female-d", name: "Female D", postCount: 0, female: true),
    ]

    func testIsMale() {
        XCTAssertTrue(reciters[0].isMale)
        XCTAssertFalse(reciters[1].isMale)
        XCTAssertTrue(reciters[2].isMale, "female nil berarti laki-laki")
        XCTAssertFalse(reciters[3].isMale)
    }

    func testMalesOnlyFiltersOutFemaleReciters() {
        let filtered = ReciterFilter.malesOnly(reciters)
        XCTAssertEqual(filtered.map(\.slug), ["male-a", "unknown-c"])
    }

    func testMalesOnlyKeepsEverythingWhenNoFemale() {
        let allMale = reciters.filter { $0.female != true }
        XCTAssertEqual(ReciterFilter.malesOnly(allMale).count, allMale.count)
    }
}

final class AsyncSemaphoreTests: XCTestCase {

    func testWithPermitRunsOperation() async throws {
        let semaphore = AsyncSemaphore(limit: 2)
        let value = await semaphore.withPermit { 42 }
        XCTAssertEqual(value, 42)
    }

    func testPermitsAreReleasedAfterUse() async {
        let semaphore = AsyncSemaphore(limit: 2)
        for _ in 0..<5 {
            _ = await semaphore.withPermit { 0 }
        }
        let available = await semaphore.availablePermits
        XCTAssertEqual(available, 2)
    }

    func testLimitsConcurrency() async {
        let semaphore = AsyncSemaphore(limit: 2)
        let tracker = ConcurrencyTracker()

        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<8 {
                group.addTask {
                    await semaphore.withPermit {
                        await tracker.enter()
                        try? await Task.sleep(for: .milliseconds(30))
                        await tracker.leave()
                    }
                }
            }
        }

        let peak = await tracker.peak
        XCTAssertLessThanOrEqual(peak, 2)
        let current = await tracker.current
        XCTAssertEqual(current, 0)
    }

    func testPermitsReleaseOnThrow() async {
        struct TestError: Error {}

        let semaphore = AsyncSemaphore(limit: 1)
        do {
            try await semaphore.withPermit { () async throws -> Void in
                throw TestError()
            }
            XCTFail("Seharusnya melempar error")
        } catch {
            // diharapkan
        }

        let available = await semaphore.availablePermits
        XCTAssertEqual(available, 1)
    }
}

/// Pencatat jumlah operasi bersamaan.
private actor ConcurrencyTracker {
    private(set) var current = 0
    private(set) var peak = 0

    func enter() {
        current += 1
        peak = max(peak, current)
    }

    func leave() {
        current -= 1
    }
}
