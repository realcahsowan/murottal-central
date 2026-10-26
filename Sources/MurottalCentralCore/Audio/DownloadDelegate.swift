import Foundation

/// Meneruskan progres & hasil unduhan dari `URLSession` ke `DownloadManager`.
final class DownloadDelegate: NSObject, URLSessionDownloadDelegate, @unchecked Sendable {

    typealias ProgressHandler = @Sendable (Double) -> Void
    typealias FinishHandler = @Sendable (Result<URL, Error>) -> Void

    private struct Entry {
        let onProgress: ProgressHandler
        let onFinish: FinishHandler
    }

    private let lock = NSLock()
    private var entries: [Int: Entry] = [:]
    private var progressByIdentifier: [Int: Double] = [:]

    func register(
        taskIdentifier: Int,
        onProgress: @escaping ProgressHandler,
        onFinish: @escaping FinishHandler
    ) {
        lock.lock()
        defer { lock.unlock() }
        entries[taskIdentifier] = Entry(onProgress: onProgress, onFinish: onFinish)
    }

    /// Progres terakhir yang dilaporkan untuk sebuah task (untuk status pause).
    func lastProgress(for taskIdentifier: Int) -> Double {
        lock.lock()
        defer { lock.unlock() }
        return progressByIdentifier[taskIdentifier] ?? -1
    }

    private func take(_ id: Int) -> Entry? {
        lock.lock()
        defer { lock.unlock() }
        progressByIdentifier[id] = nil
        return entries.removeValue(forKey: id)
    }

    private func peek(_ id: Int) -> Entry? {
        lock.lock()
        defer { lock.unlock() }
        return entries[id]
    }

    // MARK: URLSessionDownloadDelegate

    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        let identifier = downloadTask.taskIdentifier
        guard let entry = peek(identifier) else { return }

        let progress = totalBytesExpectedToWrite > 0
            ? Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
            : -1

        lock.lock()
        progressByIdentifier[identifier] = progress
        lock.unlock()

        entry.onProgress(progress)
    }

    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didFinishDownloadingTo location: URL
    ) {
        guard let entry = take(downloadTask.taskIdentifier) else { return }

        // Berkas di `location` hanya valid selama callback ini, jadi harus
        // dipindahkan sekarang juga.
        let holding = FileManager.default.temporaryDirectory
            .appending(path: "murottal-\(UUID().uuidString).download")
        do {
            try FileManager.default.moveItem(at: location, to: holding)
            entry.onFinish(.success(holding))
        } catch {
            entry.onFinish(.failure(error))
        }
    }

    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didCompleteWithError error: Error?
    ) {
        // Jika sukses, entry sudah diambil di `didFinishDownloadingTo`.
        guard let error, let entry = take(task.taskIdentifier) else { return }

        let nsError = error as NSError
        if nsError.domain == NSURLErrorDomain, nsError.code == NSURLErrorCancelled {
            // Dibatalkan lewat `pause()`/`cancel()` — bukan kegagalan nyata.
            entry.onFinish(.failure(DownloadManager.DownloadError.paused))
        } else {
            entry.onFinish(.failure(error))
        }
    }
}
