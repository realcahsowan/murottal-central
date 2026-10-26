import Foundation
import Observation

/// Favorit pengguna: trek audio & qari berbintang.
@MainActor
@Observable
public final class FavoritesStore {

    public private(set) var tracks: [AudioTrack] = []
    public private(set) var reciters: [ReciterRef] = []

    private let store: JSONFileStore

    public init(fileName: String = "favorites.json") {
        self.store = JSONFileStore(fileName: fileName)
        self.tracks = store.load([AudioTrack].self, default: [])
        self.reciters = store.load([ReciterRef].self, default: [])
    }

    // MARK: Trek

    public func isFavorite(_ track: AudioTrack) -> Bool {
        tracks.contains { $0.url == track.url }
    }

    public func toggleFavorite(_ track: AudioTrack) {
        if let idx = tracks.firstIndex(where: { $0.url == track.url }) {
            tracks.remove(at: idx)
        } else {
            tracks.insert(track, at: 0)
        }
        persist()
    }

    // MARK: Qari

    public func isStarred(slug: String) -> Bool {
        reciters.contains { $0.slug == slug }
    }

    public func toggleStar(slug: String, name: String) {
        if let idx = reciters.firstIndex(where: { $0.slug == slug }) {
            reciters.remove(at: idx)
        } else {
            reciters.insert(ReciterRef(slug: slug, name: name), at: 0)
        }
        persist()
    }

    private func persist() {
        store.save(tracks)
        store.save(reciters)
    }
}

/// Riwayat pemutaran (maksimum 200 entri).
@MainActor
@Observable
public final class PlaybackHistoryStore {

    public private(set) var entries: [HistoryEntry] = []

    private let store: JSONFileStore
    private let limit: Int

    public init(fileName: String = "history.json", limit: Int = 200) {
        self.store = JSONFileStore(fileName: fileName)
        self.limit = limit
        self.entries = store.load([HistoryEntry].self, default: [])
    }

    public func record(url: String, title: String, reciterName: String) {
        entries.removeAll { $0.url == url }
        entries.insert(
            HistoryEntry(url: url, title: title, reciterName: reciterName),
            at: 0
        )
        if entries.count > limit {
            entries = Array(entries.prefix(limit))
        }
        store.save(entries)
    }

    public func clear() {
        entries = []
        store.save(entries)
    }
}
