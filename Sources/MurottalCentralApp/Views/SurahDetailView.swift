import MurottalCentralCore
import SwiftUI

/// Semua rekaman untuk satu surah dari berbagai qari.
struct SurahDetailView: View {
    @Environment(AppState.self) private var app

    let surah: Surah

    @State private var phase: LoadPhase<SurahTag> = .loading

    var body: some View {
        AsyncContentView(
            phase: phase,
            emptyMessage: "Belum ada rekaman untuk surah ini.",
            isEmpty: { $0.items.isEmpty }
        ) { tag in
            ScrollView {
                LazyVStack(spacing: 2) {
                    ForEach(tag.items) { track in
                        // Pada endpoint tag, `title` berisi nama qari.
                        TrackRow(
                            track: track,
                            playlist: tag.items,
                            reciterName: track.title,
                            showReciter: true
                        )
                    }
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 12)
            }
        }
        .navigationTitle(surah.displayTitle)
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                Text(surah.arabic).font(.title3)
                NavigationLink(value: Route.reading(.surah(surah))) {
                    Label("Baca", systemImage: "text.book.closed")
                }
                .help("Baca surah ini dengan audio per ayat")
            }
        }
        .task { await load() }
    }

    private func load() async {
        phase = .loading
        do {
            let tag = try await app.surahTag(for: surah.slug)
            phase = .loaded(tag)
        } catch {
            phase = .failed((error as? LocalizedError)?.errorDescription ?? error.localizedDescription)
        }
    }
}
