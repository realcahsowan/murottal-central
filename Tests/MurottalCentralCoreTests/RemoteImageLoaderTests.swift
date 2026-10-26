import AppKit
import XCTest
@testable import MurottalCentralCore

/// Penghitung pemanggilan fetch.
private actor FetchCounter {
    private(set) var count = 0
    func increment() { count += 1 }
}

@MainActor
final class RemoteImageLoaderTests: XCTestCase {

    /// PNG 1×1 transparan.
    private static let pngBase64 =
        "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg=="

    private static var pngData: Data {
        Data(base64Encoded: pngBase64)!
    }

    private func url(_ path: String) -> URL {
        URL(string: "https://example.com/\(path)")!
    }

    private func makeLoader(
        counter: FetchCounter,
        maxConcurrent: Int = 2
    ) -> RemoteImageLoader {
        let data = Self.pngData
        return RemoteImageLoader(memoryLimitMB: 8, maxConcurrent: maxConcurrent) { _ in
            await counter.increment()
            return data
        }
    }

    func testLoadsAndCachesImage() async {
        let counter = FetchCounter()
        let loader = makeLoader(counter: counter)
        let target = url("a.jpg")

        let first = await loader.image(for: target)
        XCTAssertNotNil(first)

        let second = await loader.image(for: target)
        XCTAssertNotNil(second)

        let count = await counter.count
        XCTAssertEqual(count, 1, "Gambar kedua harus diambil dari cache")
        XCTAssertNotNil(loader.cachedImage(for: target))
    }

    func testDeduplicatesConcurrentRequests() async {
        let counter = FetchCounter()
        let loader = makeLoader(counter: counter)
        let target = url("b.jpg")

        async let first = loader.image(for: target)
        async let second = loader.image(for: target)
        let results = await [first, second]

        XCTAssertEqual(results.compactMap { $0 }.count, 2)
        let count = await counter.count
        XCTAssertEqual(count, 1, "Request identik yang bersamaan harus digabung")
    }

    func testPrefetchWarmsCache() async {
        let counter = FetchCounter()
        let loader = makeLoader(counter: counter)
        let targets = [url("1.jpg"), url("2.jpg"), url("3.jpg")]

        await loader.prefetch(targets)

        for target in targets {
            XCTAssertNotNil(loader.cachedImage(for: target))
        }
        let count = await counter.count
        XCTAssertEqual(count, 3)
    }

    func testPrefetchSkipsAlreadyCached() async {
        let counter = FetchCounter()
        let loader = makeLoader(counter: counter)
        let targets = [url("1.jpg"), url("2.jpg")]

        await loader.prefetch(targets)
        await loader.prefetch(targets)

        let count = await counter.count
        XCTAssertEqual(count, 2)
    }

    func testPrefetchRespectsLimit() async {
        let counter = FetchCounter()
        let loader = makeLoader(counter: counter)
        let targets = (1...10).map { url("\($0).jpg") }

        await loader.prefetch(targets, limit: 3)

        let count = await counter.count
        XCTAssertEqual(count, 3)
    }

    func testFailureReturnsNilAndIsNotCached() async {
        let counter = FetchCounter()
        struct Boom: Error {}
        let loader = RemoteImageLoader(memoryLimitMB: 8, maxConcurrent: 1) { _ in
            await counter.increment()
            throw Boom()
        }
        let target = url("missing.jpg")

        let image = await loader.image(for: target)
        XCTAssertNil(image)
        XCTAssertNil(loader.cachedImage(for: target))
    }

    func testRemoveAllClearsCache() async {
        let counter = FetchCounter()
        let loader = makeLoader(counter: counter)
        let target = url("c.jpg")

        _ = await loader.image(for: target)
        XCTAssertNotNil(loader.cachedImage(for: target))

        loader.removeAll()
        XCTAssertNil(loader.cachedImage(for: target))

        _ = await loader.image(for: target)
        let count = await counter.count
        XCTAssertEqual(count, 2)
    }
}
