import MurottalCentralCore
import SwiftUI

/// Grid semua qari dengan pencarian dan filter.
struct ReciterGridView: View {
    @Environment(AppState.self) private var app
    @Environment(AppSettings.self) private var settings

    @State private var searchText = ""
    @State private var selectedCountry = ""
    @State private var selectedDialect = ""

    private let columns = [GridItem(.adaptive(minimum: 150, maximum: 220), spacing: 16)]

    private var filtered: [Reciter] {
        CatalogSearch.reciters(
            app.reciters,
            query: searchText,
            country: selectedCountry,
            dialect: selectedDialect
        )
    }

    private var countries: [String] {
        CatalogSearch.countries(in: app.reciters)
    }

    private var dialects: [String] {
        CatalogSearch.dialects(in: app.reciters)
    }

    private var phase: LoadPhase<[Reciter]> {
        if app.isLoadingCatalog { return .loading }
        if let error = app.catalogError { return .failed(error) }
        return .loaded(filtered)
    }

    var body: some View {
        AsyncContentView(
            phase: phase,
            emptyMessage: "Tidak ada qari yang cocok dengan filter.",
            isEmpty: { $0.isEmpty }
        ) { reciters in
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(reciters) { reciter in
                        NavigationLink(value: Route.reciter(reciter)) {
                            ReciterCard(reciter: reciter)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(16)
            }
        }
        .searchable(text: $searchText, prompt: "Cari qari")
        .task(id: app.reciters.count) {
            await prefetchArtwork()
        }
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                Picker("Negara", selection: $selectedCountry) {
                    Text("Semua negara").tag("")
                    ForEach(countries, id: \.self) { Text($0).tag($0) }
                }
                Picker("Dialek", selection: $selectedDialect) {
                    Text("Semua dialek").tag("")
                    ForEach(dialects, id: \.self) { Text($0).tag($0) }
                }
            }
        }
        .navigationTitle("Qari")
    }

    /// Hangatkan cache artwork untuk kartu yang paling mungkin terlihat.
    private func prefetchArtwork() async {
        guard !settings.hideMalePhotos, !app.reciters.isEmpty else { return }
        let urls = app.reciters
            .prefix(24)
            .map { QCEndpoints.artworkURL(for: $0.slug) }
        await RemoteImageLoader.shared.prefetch(urls, limit: 24)
    }
}

struct ReciterCard: View {
    @Environment(AppSettings.self) private var settings

    let reciter: Reciter

    private var showsMujawwadBadge: Bool {
        settings.showArtworkBadges && reciter.mujawwad == true
    }

    var body: some View {
        VStack(spacing: 8) {
            ArtworkView(
                slug: reciter.slug,
                name: reciter.name,
                isFemale: reciter.female ?? false
            )
            .frame(height: 150)
            .clipped()
            .overlay(alignment: .topTrailing) {
                if reciter.postCount == 0 {
                    Text("Segera")
                        .font(.caption2.weight(.semibold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.orange, in: Capsule())
                        .foregroundStyle(.white)
                        .padding(6)
                }
            }

            VStack(spacing: 2) {
                Text(reciter.name)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                HStack(spacing: 4) {
                    Text("\(reciter.postCount) berkas")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    if showsMujawwadBadge {
                        Text("Mujawwad")
                            .font(.caption2.weight(.semibold))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(Color.accentColor.opacity(0.15), in: Capsule())
                            .foregroundStyle(Color.accentColor)
                    }
                }
            }
            .padding(.horizontal, 6)
            .padding(.bottom, 8)
        }
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.secondary.opacity(0.15))
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(reciter.name), \(reciter.postCount) berkas audio")
    }
}
