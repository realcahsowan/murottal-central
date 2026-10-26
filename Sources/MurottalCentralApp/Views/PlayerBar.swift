import MurottalCentralCore
import SwiftUI

/// Bar pemutar yang selalu tampil di bawah jendela.
struct PlayerBar: View {
    @Environment(AppState.self) private var app

    private var player: AudioPlayer { app.player }

    private var seekBinding: Binding<Double> {
        Binding(
            get: { player.currentTime },
            set: { player.seek(to: $0) }
        )
    }

    private var rateBinding: Binding<Float> {
        Binding(
            get: { player.rate },
            set: { player.rate = $0 }
        )
    }

    var body: some View {
        HStack(spacing: 16) {
            nowPlaying

            Spacer(minLength: 8)

            transportControls

            Spacer(minLength: 8)

            seekBar

            options
        }
        .padding(.horizontal, 16)
        .frame(height: 76)
        .background(.bar)
    }

    // MARK: Subviews

    private var nowPlaying: some View {
        HStack(spacing: 10) {
            if let track = player.current {
                ArtworkView(
                    slug: track.artworkIdentifier,
                    name: track.title,
                    cornerRadius: 6
                )
                .frame(width: 48, height: 48)

                VStack(alignment: .leading, spacing: 2) {
                    Text(track.title)
                        .font(.callout.weight(.medium))
                        .lineLimit(1)
                    Text(track.reciterFolderSlug)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                .frame(width: 180, alignment: .leading)
            } else {
                Image(systemName: "music.note")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                    .frame(width: 48, height: 48)
                Text("Pilih rekaman untuk mulai")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .frame(width: 180, alignment: .leading)
            }
        }
    }

    private var transportControls: some View {
        HStack(spacing: 14) {
            Button {
                player.previous()
            } label: {
                Image(systemName: "backward.fill")
            }
            .buttonStyle(.plain)
            .disabled(player.current == nil)
            .help("Sebelumnya")
            .accessibilityLabel("Trek sebelumnya")

            Button {
                player.togglePlayPause()
            } label: {
                Image(systemName: player.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 32))
            }
            .buttonStyle(.plain)
            .disabled(player.current == nil)
            .help(player.isPlaying ? "Jeda" : "Putar")
            .accessibilityLabel(player.isPlaying ? "Jeda" : "Putar")

            Button {
                player.next()
            } label: {
                Image(systemName: "forward.fill")
            }
            .buttonStyle(.plain)
            .disabled(player.current == nil)
            .help("Berikutnya")
            .accessibilityLabel("Trek berikutnya")
        }
    }

    private var seekBar: some View {
        HStack(spacing: 8) {
            Text(DurationParser.format(player.currentTime))
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: 52, alignment: .trailing)

            Slider(value: seekBinding, in: 0...max(player.duration, 1))
                .frame(minWidth: 160)

            Text(DurationParser.format(player.duration))
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: 52, alignment: .leading)
        }
        .disabled(player.current == nil)
    }

    private var options: some View {
        HStack(spacing: 10) {
            Button {
                player.toggleShuffle()
            } label: {
                Image(systemName: "shuffle")
                    .foregroundStyle(player.isShuffled ? Color.accentColor : .secondary)
            }
            .buttonStyle(.plain)
            .help("Acak")

            Button {
                player.cycleRepeatMode()
            } label: {
                Image(systemName: player.repeatMode.symbolName)
                    .foregroundStyle(player.repeatMode == .off ? Color.secondary : Color.accentColor)
            }
            .buttonStyle(.plain)
            .help("Ulangi")

            Picker("", selection: rateBinding) {
                ForEach([0.75, 1.0, 1.25, 1.5, 1.75, 2.0], id: \.self) { value in
                    Text("\(value, specifier: "%.2g")×").tag(Float(value))
                }
            }
            .labelsHidden()
            .frame(width: 78)
            .help("Kecepatan putar")
            .accessibilityLabel("Kecepatan putar")

            sleepTimerMenu
        }
    }

    private var sleepTimerMenu: some View {
        Menu {
            Button("Nonaktif") { player.cancelSleepTimer() }
                .disabled(player.sleepTimerMode == .off)

            Divider()

            ForEach(AudioPlayer.sleepTimerPresets, id: \.self) { minutes in
                Button("\(minutes) menit") { player.setSleepTimer(minutes: minutes) }
            }

            Divider()

            Button("Akhir trek ini") { player.setSleepTimerEndOfTrack() }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: player.sleepTimerMode.isActive ? "moon.zzz.fill" : "moon.zzz")
                    .foregroundStyle(player.sleepTimerMode.isActive ? Color.accentColor : .secondary)
                if let remaining = player.sleepTimerRemaining {
                    Text(DurationParser.format(remaining))
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
        .help("Sleep timer")
        .accessibilityLabel("Sleep timer")
    }
}
