import AppKit
import MurottalCentralCore
import SwiftUI

/// Menampilkan artwork qari, menghormati preferensi sembunyikan-foto.
///
/// Memakai `RemoteImageLoader` (cache memori + prefetch) alih-alih `AsyncImage`
/// agar gambar tidak diunduh ulang saat daftar di-scroll.
struct ArtworkView: View {
    @Environment(AppSettings.self) private var settings

    /// `nil` berarti tidak ada artwork yang diketahui (mis. audio per ayat).
    let slug: String?
    let name: String
    var isFemale: Bool = false
    var cornerRadius: CGFloat = 12

    @State private var image: NSImage?

    private var shouldHidePhoto: Bool {
        settings.shouldHideArtwork(isFemale: isFemale)
    }

    private var primaryURL: URL? {
        guard !shouldHidePhoto, let slug, !slug.isEmpty else { return nil }
        return QCEndpoints.artworkURL(for: slug)
    }

    private var fallbackURL: URL {
        isFemale ? QCEndpoints.artworkFallbackFemale : QCEndpoints.artworkFallbackMale
    }

    var body: some View {
        ZStack {
            if let image {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                placeholder
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .accessibilityLabel("Artwork \(name)")
        .task(id: primaryURL) {
            await load()
        }
    }

    private var placeholder: some View {
        ZStack {
            Color.secondary.opacity(0.15)
            Image(systemName: "person.fill")
                .font(.system(size: 28))
                .foregroundStyle(.secondary)
        }
    }

    private func load() async {
        let loader = RemoteImageLoader.shared

        if let primaryURL {
            if let cached = loader.cachedImage(for: primaryURL) {
                image = cached
                return
            }
            if let loaded = await loader.image(for: primaryURL) {
                image = loaded
                return
            }
        }

        image = await loader.image(for: fallbackURL)
    }
}
