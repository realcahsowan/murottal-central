import AppKit
import Foundation

/// Pemuat gambar jarak jauh dengan cache memori, de-duplikasi request, dan
/// pembatas konkurensi.
///
/// Dipakai untuk artwork qari. `@MainActor` agar bisa dibaca langsung dari
/// SwiftUI tanpa `await` tambahan.
@MainActor
public final class RemoteImageLoader {

    public typealias Fetch = @Sendable (URL) async throws -> Data

    /// Instance bersama untuk seluruh aplikasi.
    public static let shared = RemoteImageLoader()

    private let cache = NSCache<NSURL, NSImage>()
    private let limiter: AsyncSemaphore
    private let fetch: Fetch
    private var inFlight: [URL: Task<NSImage?, Never>] = [:]

    public init(
        memoryLimitMB: Int = 64,
        maxConcurrent: Int = 4,
        fetch: @escaping Fetch = RemoteImageLoader.defaultFetch
    ) {
        self.cache.totalCostLimit = max(1, memoryLimitMB) * 1024 * 1024
        self.limiter = AsyncSemaphore(limit: max(1, maxConcurrent))
        self.fetch = fetch
    }

    public static let defaultFetch: Fetch = { url in
        var request = URLRequest(url: url)
        request.setValue("MurottalCentral/0.1 (macOS)", forHTTPHeaderField: "User-Agent")
        let (data, _) = try await URLSession.shared.data(for: request)
        return data
    }

    /// Gambar dari cache (sinkron, tanpa jaringan).
    public func cachedImage(for url: URL) -> NSImage? {
        cache.object(forKey: url as NSURL)
    }

    /// Ambil gambar; memakai cache bila ada, dan menggabungkan request identik.
    public func image(for url: URL) async -> NSImage? {
        if let cached = cachedImage(for: url) { return cached }
        if let existing = inFlight[url] { return await existing.value }

        let limiter = self.limiter
        let fetch = self.fetch
        let task = Task<NSImage?, Never> {
            await limiter.wait()
            let image: NSImage?
            do {
                let data = try await fetch(url)
                image = NSImage(data: data)
            } catch {
                image = nil
            }
            await limiter.signal()
            return image
        }

        inFlight[url] = task
        let image = await task.value
        inFlight[url] = nil
        if let image {
            cache.setObject(image, forKey: url as NSURL)
        }
        return image
    }

    /// Hangatkan cache untuk sekumpulan URL (mis. artwork yang akan terlihat).
    public func prefetch(_ urls: [URL], limit: Int = 40) async {
        let targets = urls
            .prefix(limit)
            .filter { cachedImage(for: $0) == nil && inFlight[$0] == nil }

        guard !targets.isEmpty else { return }

        await withTaskGroup(of: Void.self) { group in
            for url in targets {
                group.addTask { [weak self] in
                    _ = await self?.image(for: url)
                }
            }
        }
    }

    public func removeAll() {
        cache.removeAllObjects()
    }
}
