import MurottalCentralCore
import SwiftUI

/// Modal pemilih qari per ayat dengan pencarian.
///
/// Dipakai di layar Baca. Dipilih karena daftar berisi 45 qari dengan metadata
/// (nama + bitrate) — `Menu` biasa tidak bisa dicari dan sulit dipindai.
struct AyahReciterPicker: View {
    @Environment(\.dismiss) private var dismiss

    let reciters: [AyahReciter]
    let selectedID: Int
    let onSelect: (AyahReciter) -> Void

    @State private var query = ""
    @FocusState private var searchFocused: Bool

    private var filtered: [AyahReciter] {
        AyahReciterSearch.filter(reciters, query: query)
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            searchField
            Divider()
            list
            Divider()
            footer
        }
        .frame(width: 440, height: 540)
        .onAppear {
            searchFocused = true
        }
    }

    // MARK: Bagian

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Pilih Qari").font(.headline)
                Text("Audio per ayat · \(reciters.count) qari tersedia")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .help("Tutup")
            .accessibilityLabel("Tutup")
        }
        .padding(16)
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)

            TextField("Cari nama qari…", text: $query)
                .textFieldStyle(.plain)
                .focused($searchFocused)
                .onSubmit {
                    if let first = filtered.first { select(first) }
                }

            if !query.isEmpty {
                Button {
                    query = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Bersihkan pencarian")
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    @ViewBuilder
    private var list: some View {
        if filtered.isEmpty {
            ContentUnavailableView {
                Label("Tidak Ditemukan", systemImage: "magnifyingglass")
            } description: {
                Text("Tidak ada qari yang cocok dengan “\(query)”.")
            }
            .frame(maxHeight: .infinity)
        } else {
            List(filtered) { reciter in
                Button {
                    select(reciter)
                } label: {
                    row(reciter)
                }
                .buttonStyle(.plain)
                .listRowBackground(
                    reciter.id == selectedID
                        ? Color.accentColor.opacity(0.12)
                        : Color.clear
                )
            }
            .listStyle(.inset)
        }
    }

    private func row(_ reciter: AyahReciter) -> some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(reciter.name)
                    .font(.body.weight(.medium))
                Text(reciter.bitrate.isEmpty ? reciter.subfolder : reciter.bitrate)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            if reciter.id == selectedID {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Color.accentColor)
                    .accessibilityLabel("Dipilih")
            }
        }
        .contentShape(Rectangle())
        .padding(.vertical, 3)
        .help(reciter.subfolder)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(reciter.name), \(reciter.bitrate)")
    }

    private var footer: some View {
        HStack {
            Text(query.isEmpty ? "Klik qari untuk memilih" : "\(filtered.count) hasil")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Button("Batal") { dismiss() }
                .keyboardShortcut(.cancelAction)
        }
        .padding(12)
    }

    // MARK: Aksi

    private func select(_ reciter: AyahReciter) {
        onSelect(reciter)
        dismiss()
    }
}
