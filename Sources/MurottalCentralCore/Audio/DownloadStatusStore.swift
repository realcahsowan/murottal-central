import Foundation
import Observation

/// Status unduhan sebuah trek.
public enum DownloadState: Sendable, Equatable {
    case notDownloaded
    /// `progress` bernilai 0...1, atau negatif bila ukuran total tidak diketahui.
    case downloading(progress: Double)
    /// Unduhan dijeda; `progress` menyimpan posisi terakhir (bisa negatif).
    case paused(progress: Double)
    case downloaded
    case failed(String)

    public var isDownloading: Bool {
        if case .downloading = self { return true }
        return false
    }

    public var isPaused: Bool {
        if case .paused = self { return true }
        return false
    }

    public var isDownloaded: Bool {
        if case .downloaded = self { return true }
        return false
    }

    /// Sedang berjalan atau dijeda (tampil di bagian "Sedang Diunduh").
    public var isActive: Bool { isDownloading || isPaused }

    /// Progress 0...1, atau `nil` bila indeterminate.
    public var progress: Double? {
        switch self {
        case let .downloading(value), let .paused(value):
            return value >= 0 ? value : nil
        default:
            return nil
        }
    }

    public var isIndeterminate: Bool {
        switch self {
        case let .downloading(value), let .paused(value):
            return value < 0
        default:
            return false
        }
    }
}

/// Menyimpan status unduhan untuk ditampilkan di UI.
///
/// `@MainActor` + `@Observable` agar perubahan otomatis memicu render SwiftUI.
@MainActor
@Observable
public final class DownloadStatusStore {

    public private(set) var states: [String: DownloadState] = [:]

    public nonisolated init() {}

    public func set(_ state: DownloadState, for key: String) {
        if state == .notDownloaded {
            states[key] = nil
        } else {
            states[key] = state
        }
    }

    public func state(for key: String) -> DownloadState {
        states[key] ?? .notDownloaded
    }

    /// Semua trek yang sedang berjalan atau dijeda, terurut berdasarkan key.
    public var activeDownloads: [(key: String, state: DownloadState)] {
        states
            .filter { $0.value.isActive }
            .map { (key: $0.key, state: $0.value) }
            .sorted { $0.key < $1.key }
    }

    public func removeAll() {
        states.removeAll()
    }
}
