import MurottalCentralCore
import SwiftUI

/// Detail satu qari: header, tab Playlist / Info.
struct ReciterDetailView: View {
    @Environment(AppState.self) private var app

    let reciter: Reciter

    @State private var phase: LoadPhase<ReciterCategory> = .loading
    @State private var tab = 0
    @State private var trackQuery = ""

    private var isStarred: Bool { app.favorites.isStarred(slug: reciter.slug) }

    var body: some View {
        AsyncContentView(
            phase: phase,
            emptyMessage: "Audio qari ini sedang disiapkan.",
            isEmpty: { $0.items.isEmpty }
        ) { category in
            VStack(alignment: .leading, spacing: 0) {
                header(category)
                Divider()
                Picker("", selection: $tab) {
                    Text("Playlist").tag(0)
                    Text("Info").tag(1)
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .padding(12)

                if tab == 0 {
                    playlist(category)
                } else {
                    info(category)
                }
            }
        }
        .searchable(text: $trackQuery, prompt: "Cari surah di playlist ini")
        .navigationTitle(reciter.name)
        .task { await load() }
    }

    // MARK: Bagian

    private func header(_ category: ReciterCategory) -> some View {
        HStack(alignment: .top, spacing: 16) {
            ArtworkView(
                slug: reciter.slug,
                name: reciter.name,
                isFemale: category.female ?? reciter.female ?? false
            )
            .frame(width: 120, height: 120)

            VStack(alignment: .leading, spacing: 6) {
                Text(reciter.name)
                    .font(.title2.weight(.semibold))
                Text("\(category.items.count) berkas audio · \(reciter.countryLabel) · \(reciter.dialectLabel)")
                    .font(.callout)
                    .foregroundStyle(.secondary)

                Button {
                    app.favorites.toggleStar(slug: reciter.slug, name: reciter.name)
                } label: {
                    Label(isStarred ? "Berbintang" : "Bintangi", systemImage: isStarred ? "star.fill" : "star")
                }
                .buttonStyle(.bordered)
                .tint(isStarred ? .yellow : nil)
            }
            Spacer()
        }
        .padding(16)
    }

    private func playlist(_ category: ReciterCategory) -> some View {
        let items = CatalogSearch.tracks(category.items, query: trackQuery)

        return Group {
            if items.isEmpty {
                ContentUnavailableView {
                    Label("Tidak Ditemukan", systemImage: "magnifyingglass")
                } description: {
                    Text("Tidak ada surah yang cocok dengan “\(trackQuery)”.")
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 2) {
                        ForEach(items) { track in
                            TrackRow(
                                track: track,
                                playlist: items,
                                reciterName: reciter.name
                            )
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.bottom, 12)
                }
            }
        }
    }

    private func info(_ category: ReciterCategory) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                if let description = category.description, !description.isEmpty {
                    Text(stripHTML(description))
                        .font(.body)
                        .textSelection(.enabled)
                } else {
                    Text("Tidak ada deskripsi.")
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
        }
    }

    // MARK: Helpers

    private func load() async {
        phase = .loading
        do {
            let category = try await app.category(for: reciter.slug)
            phase = .loaded(category)
        } catch {
            phase = .failed((error as? LocalizedError)?.errorDescription ?? error.localizedDescription)
        }
    }

    /// Buang tag HTML sederhana dari deskripsi.
    private func stripHTML(_ html: String) -> String {
        html.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
