import MurottalCentralCore
import SwiftUI

/// Daftar 114 surah.
struct SurahListView: View {
    @Environment(AppState.self) private var app

    @State private var searchText = ""

    private var filtered: [Surah] {
        CatalogSearch.surahs(app.surahs, query: searchText)
    }

    private var phase: LoadPhase<[Surah]> {
        if app.isLoadingCatalog { return .loading }
        if let error = app.catalogError { return .failed(error) }
        return .loaded(filtered)
    }

    var body: some View {
        AsyncContentView(
            phase: phase,
            emptyMessage: "Tidak ada surah yang cocok.",
            isEmpty: { $0.isEmpty }
        ) { surahs in
            List(surahs) { surah in
                NavigationLink(value: Route.surah(surah)) {
                    HStack(spacing: 12) {
                        Text(String(format: "%03d", surah.id))
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                            .frame(width: 34, alignment: .leading)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(surah.transliteration).font(.body.weight(.medium))
                            Text(surah.translation).font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(surah.arabic)
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 2)
                }
            }
            .listStyle(.inset)
        }
        .searchable(text: $searchText, prompt: "Cari surah")
        .navigationTitle("Surah")
    }
}
