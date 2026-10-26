import SwiftUI

/// Fase pemuatan data yang seragam untuk semua layar.
enum LoadPhase<Value> {
    case loading
    case failed(String)
    case loaded(Value)
}

/// Menampilkan state loading / error / kosong / konten secara konsisten.
struct AsyncContentView<Value, Content: View>: View {
    let phase: LoadPhase<Value>
    var emptyMessage: String = "Tidak ada data."
    var isEmpty: ((Value) -> Bool)?
    @ViewBuilder let content: (Value) -> Content

    var body: some View {
        switch phase {
        case .loading:
            VStack(spacing: 12) {
                ProgressView()
                Text("Memuat…")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

        case let .failed(message):
            ContentUnavailableView {
                Label("Gagal Memuat", systemImage: "exclamationmark.triangle")
            } description: {
                Text(message)
            }

        case let .loaded(value):
            if let isEmpty, isEmpty(value) {
                ContentUnavailableView {
                    Label("Kosong", systemImage: "tray")
                } description: {
                    Text(emptyMessage)
                }
            } else {
                content(value)
            }
        }
    }
}
