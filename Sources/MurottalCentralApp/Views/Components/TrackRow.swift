import MurottalCentralCore
import SwiftUI

/// Satu baris trek audio dalam daftar putar.
struct TrackRow: View {
    @Environment(AppState.self) private var app

    let track: AudioTrack
    let playlist: [AudioTrack]
    let reciterName: String
    /// Untuk daftar "surah", yang ditampilkan adalah nama qari.
    var showReciter = false

    private var isCurrent: Bool {
        app.player.current?.url == track.url
    }

    private var isFavorite: Bool {
        app.favorites.isFavorite(track)
    }

    private var downloadState: DownloadState {
        app.downloadState(for: track)
    }

    var body: some View {
        HStack(spacing: 12) {
            Button {
                app.play(track, in: playlist, reciterName: reciterName)
            } label: {
                Image(systemName: isCurrent && app.player.isPlaying ? "speaker.wave.2.fill" : "play.fill")
                    .frame(width: 20)
            }
            .buttonStyle(.plain)
            .help("Putar \(track.title)")

            VStack(alignment: .leading, spacing: 2) {
                Text(showReciter ? reciterName : track.title)
                    .font(.body.weight(.medium))
                    .lineLimit(1)
                Text(track.formattedDuration)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            downloadControl

            Button {
                app.favorites.toggleFavorite(track)
            } label: {
                Image(systemName: isFavorite ? "heart.fill" : "heart")
                    .foregroundStyle(isFavorite ? .pink : .secondary)
            }
            .buttonStyle(.plain)
            .help(isFavorite ? "Hapus dari favorit" : "Tambah ke favorit")
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(isCurrent ? Color.accentColor.opacity(0.12) : Color.clear)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            app.play(track, in: playlist, reciterName: reciterName)
        }
    }

    /// Tombol/indikator unduhan sesuai status.
    @ViewBuilder
    private var downloadControl: some View {
        switch downloadState {
        case .downloading:
            HStack(spacing: 8) {
                ZStack {
                    if let progress = downloadState.progress {
                        ProgressView(value: progress)
                            .progressViewStyle(.circular)
                            .controlSize(.small)
                    } else {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .controlSize(.small)
                    }
                }
                .frame(width: 18, height: 18)
                .help("Mengunduh…")

                Button {
                    Task { await app.pauseDownload(track) }
                } label: {
                    Image(systemName: "pause.circle")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Jeda unduhan")
            }

        case .paused:
            HStack(spacing: 8) {
                Image(systemName: "pause.circle.fill")
                    .foregroundStyle(.orange)
                    .help("Unduhan dijeda")

                Button {
                    Task { await app.download(track) }
                } label: {
                    Image(systemName: "play.circle")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Lanjutkan unduhan")

                Button {
                    Task { await app.cancelDownload(track) }
                } label: {
                    Image(systemName: "xmark.circle")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Batalkan unduhan")
            }

        case .downloaded:
            HStack(spacing: 8) {
                Image(systemName: "arrow.down.circle.fill")
                    .foregroundStyle(.green)
                    .help("Tersedia offline")
                Button {
                    Task { await app.deleteDownload(track) }
                } label: {
                    Image(systemName: "trash")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Hapus unduhan")
            }

        case let .failed(message):
            Button {
                Task { await app.download(track) }
            } label: {
                Image(systemName: "exclamationmark.arrow.triangle.2.circlepath")
                    .foregroundStyle(.orange)
            }
            .buttonStyle(.plain)
            .help("Unduhan gagal: \(message). Klik untuk mencoba lagi.")

        case .notDownloaded:
            Button {
                Task { await app.download(track) }
            } label: {
                Image(systemName: "arrow.down.circle")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .help("Unduh untuk pemutaran offline")
        }
    }
}
