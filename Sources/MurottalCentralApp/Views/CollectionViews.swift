import MurottalCentralCore
import SwiftUI

// MARK: - Favorit (trek)

struct FavoritesView: View {
    @Environment(AppState.self) private var app

    var body: some View {
        Group {
            if app.favorites.tracks.isEmpty {
                ContentUnavailableView {
                    Label("Belum Ada Favorit", systemImage: "heart")
                } description: {
                    Text("Tekan ikon hati pada trek untuk menyimpannya di sini.")
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 2) {
                        ForEach(app.favorites.tracks) { track in
                            TrackRow(
                                track: track,
                                playlist: app.favorites.tracks,
                                reciterName: track.reciterFolderSlug
                            )
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 12)
                }
            }
        }
        .navigationTitle("Favorit")
    }
}

// MARK: - Qari berbintang

struct StarredRecitersView: View {
    @Environment(AppState.self) private var app

    /// Hanya qari yang ada di katalog aktif (kebijakan: qari laki-laki).
    private var starred: [ReciterRef] {
        app.favorites.reciters.filter { app.reciter(slug: $0.slug) != nil }
    }

    var body: some View {
        Group {
            if starred.isEmpty {
                ContentUnavailableView {
                    Label("Belum Ada Qari Berbintang", systemImage: "star")
                } description: {
                    Text("Bintangi qari favoritmu dari halaman detail qari.")
                }
            } else {
                List(starred) { ref in
                    if let reciter = app.reciter(slug: ref.slug) {
                        NavigationLink(value: Route.reciter(reciter)) {
                            HStack(spacing: 12) {
                                ArtworkView(slug: ref.slug, name: ref.name)
                                    .frame(width: 44, height: 44)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(ref.name).font(.body.weight(.medium))
                                    Text("\(reciter.postCount) berkas")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
                .listStyle(.inset)
            }
        }
        .navigationTitle("Qari Berbintang")
    }
}

// MARK: - Riwayat

struct HistoryView: View {
    @Environment(AppState.self) private var app

    private var playlist: [AudioTrack] {
        app.history.entries.map { AudioTrack(title: $0.title, url: $0.url) }
    }

    var body: some View {
        Group {
            if app.history.entries.isEmpty {
                ContentUnavailableView {
                    Label("Riwayat Kosong", systemImage: "clock.arrow.circlepath")
                } description: {
                    Text("Trek yang kamu putar akan muncul di sini.")
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 2) {
                        ForEach(app.history.entries) { entry in
                            TrackRow(
                                track: AudioTrack(title: entry.title, url: entry.url),
                                playlist: playlist,
                                reciterName: entry.reciterName,
                                showReciter: true
                            )
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 12)
                }
            }
        }
        .navigationTitle("Riwayat")
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button("Bersihkan") { app.history.clear() }
                    .disabled(app.history.entries.isEmpty)
            }
        }
    }
}

// MARK: - Unduhan

struct DownloadsView: View {
    @Environment(AppState.self) private var app

    @State private var totalSize: Int64 = 0

    private var active: [(key: String, state: DownloadState)] {
        app.downloadStatus.activeDownloads
    }

    private var completed: [String] {
        app.downloadedURLs.keys.sorted()
    }

    private func fileName(_ url: String) -> String {
        url.split(separator: "/").last.map(String.init) ?? url
    }

    private func track(for key: String) -> AudioTrack {
        AudioTrack(title: fileName(key), url: key)
    }

    var body: some View {
        Group {
            if active.isEmpty && completed.isEmpty {
                ContentUnavailableView {
                    Label("Belum Ada Unduhan", systemImage: "arrow.down.circle")
                } description: {
                    Text("Trek yang diunduh bisa diputar tanpa koneksi internet.")
                }
            } else {
                List {
                    if !active.isEmpty {
                        Section("Sedang Diunduh") {
                            ForEach(active, id: \.key) { item in
                                activeRow(key: item.key, state: item.state)
                            }
                        }
                    }

                    if !completed.isEmpty {
                        Section("Selesai (\(completed.count))") {
                            ForEach(completed, id: \.self) { key in
                                HStack(spacing: 10) {
                                    Image(systemName: "waveform")
                                        .foregroundStyle(.secondary)
                                    Text(fileName(key))
                                        .font(.callout)
                                        .lineLimit(1)
                                }
                            }
                        }
                    }
                }
                .listStyle(.inset)
            }
        }
        .navigationTitle("Unduhan")
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                Text(ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file))
                    .foregroundStyle(.secondary)
                Button("Hapus Semua") {
                    Task {
                        await app.deleteAllDownloads()
                        totalSize = await app.downloadSize()
                    }
                }
                .disabled(completed.isEmpty)
            }
        }
        .task(id: completed.count) {
            totalSize = await app.downloadSize()
        }
    }

    @ViewBuilder
    private func activeRow(key: String, state: DownloadState) -> some View {
        HStack(spacing: 10) {
            Text(fileName(key))
                .font(.callout)
                .lineLimit(1)

            Spacer()

            if let progress = state.progress {
                ProgressView(value: progress)
                    .frame(width: 110)
                Text("\(Int((progress * 100).rounded()))%")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .frame(width: 40, alignment: .trailing)
            } else {
                ProgressView().controlSize(.small)
            }

            if state.isPaused {
                Button {
                    Task { await app.download(track(for: key)) }
                } label: {
                    Image(systemName: "play.circle")
                }
                .buttonStyle(.plain)
                .help("Lanjutkan")
            } else {
                Button {
                    Task { await app.pauseDownload(track(for: key)) }
                } label: {
                    Image(systemName: "pause.circle")
                }
                .buttonStyle(.plain)
                .help("Jeda")
            }

            Button {
                Task { await app.cancelDownload(track(for: key)) }
            } label: {
                Image(systemName: "xmark.circle")
            }
            .buttonStyle(.plain)
            .help("Batalkan")
        }
    }
}
