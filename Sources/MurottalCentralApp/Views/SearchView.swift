import MurottalCentralCore
import SwiftUI

/// Pencarian global: qari dan surah.
struct SearchView: View {
    @Environment(AppState.self) private var app

    @State private var query = ""
    @State private var tab: Tab = .reciters

    enum Tab: String, CaseIterable, Identifiable {
        case reciters = "Qari"
        case surahs = "Surah"
        var id: String { rawValue }
    }

    private let columns = [GridItem(.adaptive(minimum: 150, maximum: 220), spacing: 16)]

    private var reciterResults: [Reciter] {
        CatalogSearch.reciters(app.reciters, query: query)
    }

    private var surahResults: [Surah] {
        CatalogSearch.surahs(app.surahs, query: query)
    }

    var body: some View {
        VStack(spacing: 0) {
            Picker("", selection: $tab) {
                ForEach(Tab.allCases) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .padding(12)

            content
        }
        .searchable(text: $query, prompt: "Cari qari atau surah")
        .navigationTitle("Cari")
    }

    @ViewBuilder
    private var content: some View {
        if app.isLoadingCatalog {
            ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let error = app.catalogError {
            ContentUnavailableView {
                Label("Gagal Memuat", systemImage: "exclamationmark.triangle")
            } description: {
                Text(error)
            }
        } else {
            switch tab {
            case .reciters: reciterResultsView
            case .surahs: surahResultsView
            }
        }
    }

    @ViewBuilder
    private var reciterResultsView: some View {
        if reciterResults.isEmpty {
            emptyView("Tidak ada qari yang cocok dengan “\(query)”.")
        } else {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(reciterResults) { reciter in
                        NavigationLink(value: Route.reciter(reciter)) {
                            ReciterCard(reciter: reciter)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(16)
            }
            .safeAreaInset(edge: .top) {
                resultCount(reciterResults.count, unit: "qari")
            }
        }
    }

    @ViewBuilder
    private var surahResultsView: some View {
        if surahResults.isEmpty {
            emptyView("Tidak ada surah yang cocok dengan “\(query)”.")
        } else {
            List(surahResults) { surah in
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
                        Text(surah.arabic).font(.title3).foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 2)
                }
            }
            .listStyle(.inset)
        }
    }

    private func emptyView(_ message: String) -> some View {
        ContentUnavailableView {
            Label("Tidak Ditemukan", systemImage: "magnifyingglass")
        } description: {
            Text(message)
        }
    }

    private func resultCount(_ count: Int, unit: String) -> some View {
        Text("\(count) \(unit)")
            .font(.caption)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
            .background(.bar)
    }
}
