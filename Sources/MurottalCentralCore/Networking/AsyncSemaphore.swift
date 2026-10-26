import Foundation

/// Semaphore async sederhana untuk membatasi jumlah operasi bersamaan.
///
/// Dipakai agar aplikasi tidak membanjiri API (Cloudflare dapat membalas 403
/// bila terlalu banyak request paralel).
public actor AsyncSemaphore {

    private let limit: Int
    private var available: Int
    private var waiters: [CheckedContinuation<Void, Never>] = []

    public init(limit: Int) {
        precondition(limit > 0, "limit harus > 0")
        self.limit = limit
        self.available = limit
    }

    /// Ambil satu izin; menunggu bila kuota habis.
    public func wait() async {
        if available > 0 {
            available -= 1
            return
        }
        await withCheckedContinuation { continuation in
            waiters.append(continuation)
        }
    }

    /// Lepaskan satu izin.
    public func signal() {
        if waiters.isEmpty {
            available = min(available + 1, limit)
        } else {
            waiters.removeFirst().resume()
        }
    }

    /// Jalankan `operation` dengan izin, lalu lepaskan otomatis.
    public func withPermit<T: Sendable>(
        _ operation: () async throws -> T
    ) async rethrows -> T {
        await wait()
        defer { signal() }
        return try await operation()
    }

    /// Jumlah izin yang tersedia saat ini (untuk pengujian).
    public var availablePermits: Int { available }
}
