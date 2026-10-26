import MurottalCentralCore
import SwiftUI

/// Daftar 30 juz.
struct JuzListView: View {
    @Environment(AppState.self) private var app

    private func surahName(_ number: Int) -> String {
        app.surahs.first { $0.id == number }?.transliteration ?? "Surah \(number)"
    }

    var body: some View {
        Group {
            if let error = app.juzError {
                ContentUnavailableView {
                    Label("Gagal Memuat Juz", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(error)
                } actions: {
                    Button("Coba Lagi") { Task { await app.loadJuzIfNeeded() } }
                }
            } else if app.juz.isEmpty {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(app.juz) { juz in
                    NavigationLink(value: Route.juz(juz)) {
                        HStack(spacing: 12) {
                            Text("\(juz.index)")
                                .font(.title3.monospacedDigit().weight(.semibold))
                                .frame(width: 34, alignment: .leading)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Juz \(juz.index)").font(.body.weight(.medium))
                                Text(rangeText(for: juz))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
                .listStyle(.inset)
            }
        }
        .navigationTitle("Juz")
        .task { await app.loadJuzIfNeeded() }
    }

    private func rangeText(for juz: Juz) -> String {
        "\(surahName(juz.start.surah)) \(juz.start.surah):\(juz.start.verse) → "
            + "\(surahName(juz.end.surah)) \(juz.end.surah):\(juz.end.verse)"
    }
}

/// Surah-surah yang tercakup dalam satu juz.
struct JuzDetailView: View {
    @Environment(AppState.self) private var app

    let juz: Juz

    private var surahs: [Surah] {
        app.surahs.filter { $0.id >= juz.start.surah && $0.id <= juz.end.surah }
    }

    var body: some View {
        Group {
            if app.surahs.isEmpty {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
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
                            Text(surah.arabic).font(.title3).foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 2)
                    }
                }
                .listStyle(.inset)
            }
        }
        .navigationTitle("Juz \(juz.index)")
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                Text("\(surahs.count) surah").font(.caption).foregroundStyle(.secondary)
                NavigationLink(value: Route.reading(.juz(juz))) {
                    Label("Baca Juz", systemImage: "text.book.closed")
                }
                .help("Baca juz ini dengan audio per ayat")
            }
        }
    }
}
