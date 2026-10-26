import MurottalCentralCore
import SwiftUI

/// Informasi aplikasi, sumber data, dan atribusi.
struct AboutView: View {
    @Environment(AppState.self) private var app

    private let version = "0.4.2"

    private var totalTracks: Int {
        app.reciters.reduce(0) { $0 + $1.postCount }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header

                if !app.reciters.isEmpty {
                    catalogStats
                }

                sourcesSection
                attributionSection
                legalSection
            }
            .frame(maxWidth: 620, alignment: .leading)
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle("Tentang")
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                Image(systemName: "waveform.circle.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(Color.accentColor)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Murottal Central").font(.title.weight(.semibold))
                    Text("Versi \(version) · macOS")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }
            Text("Aplikasi desktop untuk mendengarkan, menjelajahi, dan mengunduh murottal Al-Qur'an dari ratusan qari.")
                .foregroundStyle(.secondary)
        }
    }

    private var catalogStats: some View {
        GroupBox("Katalog saat ini") {
            HStack(spacing: 32) {
                stat(value: "\(app.reciters.count)", label: "Qari")
                stat(value: "\(app.surahs.count)", label: "Surah")
                stat(value: totalTracks.formatted(), label: "Berkas audio")
            }
            .padding(.vertical, 4)
        }
    }

    private func stat(value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value).font(.title2.weight(.semibold).monospacedDigit())
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
    }

    private var sourcesSection: some View {
        GroupBox("Sumber data") {
            VStack(alignment: .leading, spacing: 10) {
                sourceRow(
                    title: "Quran Central",
                    subtitle: "Katalog qari, surah, dan teks Qur'an",
                    url: "https://qurancentral.com/audio"
                )
                Divider()
                sourceRow(
                    title: "Muslim Central",
                    subtitle: "Berkas audio rekaman",
                    url: "https://muslimcentral.com"
                )
                Divider()
                sourceRow(
                    title: "EveryAyah",
                    subtitle: "Audio per ayat (45 qari)",
                    url: "https://everyayah.com"
                )
                Divider()
                sourceRow(
                    title: "Quran.com",
                    subtitle: "Terjemahan Indonesia (Kemenag)",
                    url: "https://quran.com"
                )
            }
            .padding(.vertical, 4)
        }
    }

    private func sourceRow(title: String, subtitle: String, url: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.body.weight(.medium))
            Text(subtitle).font(.caption).foregroundStyle(.secondary)
            if let link = URL(string: url) {
                Link(url, destination: link)
                    .font(.caption)
            }
        }
    }

    private var attributionSection: some View {
        GroupBox("Atribusi & dukungan") {
            VStack(alignment: .leading, spacing: 10) {
                Text("Seluruh rekaman murottal berasal dari Muslim Central. Silakan dukung mereka agar layanan ini tetap gratis dan bebas iklan.")
                    .font(.callout)
                HStack(spacing: 12) {
                    if let donate = URL(string: "https://qurancentral.com/donate") {
                        Link("Dukung Muslim Central", destination: donate)
                    }
                    if let help = URL(string: "https://help.muslimcentral.com") {
                        Link("Pusat Bantuan", destination: help)
                    }
                }
                .font(.callout)
            }
            .padding(.vertical, 4)
        }
    }

    private var legalSection: some View {
        GroupBox("Catatan legal") {
            Text("""
            Murottal Central adalah klien pihak ketiga yang tidak berafiliasi resmi \
            dengan Quran Central maupun Muslim Central. Data dan audio diambil dari \
            endpoint publik milik Quran Central. Hak cipta setiap rekaman tetap milik \
            qari dan/atau label terkait. Untuk penggunaan pribadi; untuk distribusi \
            ulang harap memperoleh izin dari pemegang hak.
            """)
            .font(.caption)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.vertical, 4)
        }
    }
}
