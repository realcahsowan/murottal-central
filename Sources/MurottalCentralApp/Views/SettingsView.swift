import MurottalCentralCore
import SwiftUI

/// Preferensi aplikasi.
struct SettingsView: View {
    @Environment(AppState.self) private var app
    @Environment(AppSettings.self) private var settings

    @State private var downloadSize: Int64 = 0
    @State private var statusMessage: String?

    private var previewFont: Font {
        if let name = settings.quranFont.postScriptName {
            return .custom(name, size: settings.arabicFontSize)
        }
        return .system(size: settings.arabicFontSize)
    }

    var body: some View {
        @Bindable var settings = settings

        Form {
            Section("Tampilan") {
                Picker("Tema", selection: $settings.theme) {
                    ForEach(AppSettings.Theme.allCases) { theme in
                        Text(theme.label).tag(theme)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section("Terjemahan") {
                Picker("Bahasa terjemahan", selection: $settings.translationLanguage) {
                    ForEach(TranslationLanguage.allCases) { language in
                        Text(language.label).tag(language)
                    }
                }
                Text("Terjemahan Indonesia (Kemenag) diambil dari Quran.com; terjemahan Inggris dari Quran Central.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Teks Qur'an") {
                Picker("Font", selection: $settings.quranFont) {
                    ForEach(QuranFont.allCases) { font in
                        Text(font.label).tag(font)
                    }
                }

                HStack {
                    Text("Ukuran")
                    Slider(value: $settings.arabicFontSize, in: 18...48, step: 1)
                    Text("\(Int(settings.arabicFontSize)) pt")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                        .frame(width: 44, alignment: .trailing)
                }

                Text("بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ")
                    .font(previewFont)
                    .lineSpacing(settings.quranFont.recommendedLineSpacing)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .environment(\.layoutDirection, .rightToLeft)
                    .padding(.vertical, 4)

                Text("Font Uthmani & IndoPak sama dengan yang dipakai Quran Central di web (dikonversi dari WOFF2 ke TTF).")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Foto Qari") {
                Label("Aplikasi ini hanya menampilkan qari laki-laki.", systemImage: "info.circle")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                Toggle("Sembunyikan foto qari", isOn: $settings.hideMalePhotos)
                Toggle("Tampilkan badge gaya (Mujawwad)", isOn: $settings.showArtworkBadges)
                Text("Bila foto disembunyikan, aplikasi memakai artwork netral sebagai gantinya.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Penyimpanan") {
                LabeledContent("Ukuran unduhan") {
                    Text(ByteCountFormatter.string(fromByteCount: downloadSize, countStyle: .file))
                        .foregroundStyle(.secondary)
                }
                LabeledContent("Lokasi") {
                    Text(DownloadManager.defaultRoot().path)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                        .lineLimit(2)
                        .truncationMode(.middle)
                }

                Button("Hapus Semua Unduhan", role: .destructive) {
                    Task {
                        await app.deleteAllDownloads()
                        downloadSize = await app.downloadSize()
                        statusMessage = "Semua unduhan dihapus."
                    }
                }

                Button("Kosongkan Cache") {
                    Task {
                        await app.clearCaches()
                        statusMessage = "Cache dikosongkan."
                    }
                }
            }

            Section("Lainnya") {
                Button("Kembalikan Pengaturan Awal") {
                    settings.reset()
                    statusMessage = "Pengaturan dikembalikan ke awal."
                }
            }

            if let statusMessage {
                Section {
                    Label(statusMessage, systemImage: "checkmark.circle")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Pengaturan")
        .task {
            downloadSize = await app.downloadSize()
        }
    }
}
