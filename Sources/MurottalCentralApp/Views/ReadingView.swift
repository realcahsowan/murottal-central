import MurottalCentralCore
import SwiftUI

// MARK: - Daftar pilihan baca

/// Pintu masuk fitur baca: pilih surah atau juz.
struct ReadingHomeView: View {
    @Environment(AppState.self) private var app

    @State private var mode: Mode = .surah

    enum Mode: String, CaseIterable, Identifiable {
        case surah = "Surah"
        case juz = "Juz"
        var id: String { rawValue }
    }

    var body: some View {
        VStack(spacing: 0) {
            Picker("", selection: $mode) {
                ForEach(Mode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .padding(12)

            switch mode {
            case .surah: surahList
            case .juz: juzList
            }
        }
        .navigationTitle("Baca")
        .task {
            await app.loadJuzIfNeeded()
            await app.loadReadingIfNeeded()
        }
    }

    private var surahList: some View {
        List(app.surahs) { surah in
            NavigationLink(value: Route.reading(.surah(surah))) {
                HStack(spacing: 12) {
                    Text(String(format: "%03d", surah.id))
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                        .frame(width: 34, alignment: .leading)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(surah.transliteration).font(.body.weight(.medium))
                        Text(surah.translation)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text(surah.arabic).font(.title3).foregroundStyle(.secondary)
                }
                .padding(.vertical, 2)
            }
        }
        .listStyle(.inset)
    }

    private var juzList: some View {
        Group {
            if let error = app.juzError {
                ContentUnavailableView {
                    Label("Gagal Memuat Juz", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(error)
                }
            } else if app.juz.isEmpty {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(app.juz) { juz in
                    NavigationLink(value: Route.reading(.juz(juz))) {
                        HStack(spacing: 12) {
                            Text("\(juz.index)")
                                .font(.title3.monospacedDigit().weight(.semibold))
                                .frame(width: 34, alignment: .leading)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Juz \(juz.index)").font(.body.weight(.medium))
                                Text(juzRangeText(juz))
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
    }

    private func juzRangeText(_ juz: Juz) -> String {
        let startName = app.surahs.first { $0.id == juz.start.surah }?.transliteration ?? "Surah \(juz.start.surah)"
        let endName = app.surahs.first { $0.id == juz.end.surah }?.transliteration ?? "Surah \(juz.end.surah)"
        return "\(startName) \(juz.start.surah):\(juz.start.verse) → \(endName) \(juz.end.surah):\(juz.end.verse)"
    }
}

// MARK: - Layar baca

/// Menampilkan ayat-ayat untuk satu surah/juz, dengan audio per ayat.
struct ReadingView: View {
    @Environment(AppState.self) private var app
    @Environment(AppSettings.self) private var settings

    let scope: ReadingScope

    @State private var verses: [QuranVerse] = []
    @State private var errorMessage: String?
    @State private var isReciterPickerPresented = false

    var body: some View {
        Group {
            if let errorMessage {
                ContentUnavailableView {
                    Label("Gagal Memuat", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(errorMessage)
                } actions: {
                    Button("Coba Lagi") { Task { await load() } }
                }
            } else if verses.isEmpty {
                ProgressView("Memuat ayat…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                content
            }
        }
        .navigationTitle(scope.title)
        .toolbar { toolbar }
        .task(id: scope) { await load() }
        .task(id: settings.translationLanguage) {
            await app.loadTranslation(settings.translationLanguage)
        }
        .onChange(of: settings.quranFont) { _, _ in
            // Ganti teks Arab sesuai font (Uthmani ↔ IndoPak).
            verses = app.readingVerses(for: scope, font: settings.quranFont)
        }
        .sheet(isPresented: $isReciterPickerPresented) {
            AyahReciterPicker(
                reciters: app.ayahReciters,
                selectedID: app.selectedAyahReciterID
            ) { reciter in
                app.selectedAyahReciterID = reciter.id
            }
        }
    }

    // MARK: Konten

    private var content: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    header

                    ForEach(verses) { verse in
                        VerseCard(
                            verse: verse,
                            translation: app.translationText(
                                for: verse,
                                language: settings.translationLanguage
                            ),
                            isCurrent: app.isPlayingVerse(verse),
                            onPlay: { app.playVerse(verse, in: verses) }
                        )
                        .id(verse.id)
                    }
                }
                .padding(16)
            }
            .onChange(of: app.player.current?.url) { _, _ in
                guard let id = app.currentReadingVerseID else { return }
                withAnimation(.easeInOut(duration: 0.25)) {
                    proxy.scrollTo(id, anchor: .center)
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(scope.title).font(.title2.weight(.semibold))
            Text(scope.subtitle).font(.callout).foregroundStyle(.secondary)
            Text("\(verses.count) ayat · audio per ayat")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 4)
    }

    // MARK: Toolbar

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItemGroup(placement: .automatic) {
            translationMenu
            reciterButton

            Button {
                app.playPage(verses)
            } label: {
                Label("Putar halaman", systemImage: "play.circle")
            }
            .disabled(verses.isEmpty)
            .help("Putar semua ayat di halaman ini secara berurutan")
        }
    }

    private var translationMenu: some View {
        Menu {
            ForEach(TranslationLanguage.allCases) { language in
                Button {
                    settings.translationLanguage = language
                    Task { await app.loadTranslation(language) }
                } label: {
                    if language == settings.translationLanguage {
                        Label(language.label, systemImage: "checkmark")
                    } else {
                        Text(language.label)
                    }
                }
            }
        } label: {
            Label(
                settings.translationLanguage.shortLabel,
                systemImage: settings.translationLanguage == .none
                    ? "text.bubble"
                    : "text.bubble.fill"
            )
        }
        .help("Pilih bahasa terjemahan")
    }

    private var reciterButton: some View {
        Button {
            isReciterPickerPresented = true
        } label: {
            Label(
                app.selectedAyahReciter?.name ?? "Qari",
                systemImage: "person.wave.2"
            )
            .lineLimit(1)
        }
        .help("Pilih qari untuk audio per ayat")
        .accessibilityLabel("Pilih qari. Sekarang: \(app.selectedAyahReciter?.name ?? "belum dipilih")")
    }

    // MARK: Data

    private func load() async {
        errorMessage = nil
        await app.loadReadingIfNeeded()

        if app.quranUthmaniVerses.isEmpty, let error = app.readingError {
            errorMessage = error
            return
        }

        verses = app.readingVerses(for: scope, font: settings.quranFont)
        await app.loadTranslation(settings.translationLanguage)
    }
}

// MARK: - Kartu ayat

private struct VerseCard: View {
    @Environment(AppSettings.self) private var settings

    let verse: QuranVerse
    let translation: String?
    let isCurrent: Bool
    let onPlay: () -> Void

    /// Font Arab sesuai pilihan pengguna; jatuh ke font sistem bila tidak tersedia.
    private var arabicFont: Font {
        if let name = settings.quranFont.postScriptName,
           QuranFontRegistry.isAvailable(settings.quranFont) {
            return .custom(name, size: settings.arabicFontSize)
        }
        return .system(size: settings.arabicFontSize)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Text(verse.id)
                    .font(.caption.monospacedDigit().weight(.semibold))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2)
                    .background(
                        isCurrent
                            ? Color.accentColor.opacity(0.20)
                            : Color.secondary.opacity(0.12),
                        in: Capsule()
                    )
                    .foregroundStyle(isCurrent ? Color.accentColor : Color.secondary)

                Spacer()

                Button(action: onPlay) {
                    Image(systemName: isCurrent ? "speaker.wave.2.fill" : "play.circle")
                        .font(.title3)
                        .foregroundStyle(isCurrent ? Color.accentColor : Color.secondary)
                }
                .buttonStyle(.plain)
                .help("Putar ayat \(verse.id)")
                .accessibilityLabel("Putar ayat \(verse.id)")
            }

            // Blok teks Arab — arah layout RTL.
            // Catatan: dalam RTL, `.leading` berada di KANAN dan `.trailing` di kiri.
            // Karena itu alignment memakai `.leading` agar teks rata kanan.
            Text(QuranTextSanitizer.display(verse.text))
                .font(arabicFont)
                .lineSpacing(settings.quranFont.recommendedLineSpacing)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .textSelection(.enabled)
                .environment(\.layoutDirection, .rightToLeft)

            if let translation, !translation.isEmpty {
                Text(translation)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .textSelection(.enabled)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(
                    isCurrent
                        ? Color.accentColor.opacity(0.08)
                        : Color(nsColor: .controlBackgroundColor)
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(
                    isCurrent
                        ? Color.accentColor.opacity(0.5)
                        : Color.secondary.opacity(0.12)
                )
        )
        .accessibilityElement(children: .contain)
    }
}
