import MurottalCentralCore
import SwiftUI

/// Qari Masjidil Haram (Makkah) dan Masjid Nabawi (Madinah).
struct HaramainView: View {
    @Environment(AppState.self) private var app

    private let columns = [GridItem(.adaptive(minimum: 150, maximum: 220), spacing: 16)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                ForEach(HaramainData.groups) { group in
                    VStack(alignment: .leading, spacing: 12) {
                        Text(group.title)
                            .font(.title3.weight(.semibold))

                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(group.reciters) { ref in
                                NavigationLink(value: Route.reciter(reciter(for: ref))) {
                                    ReciterCard(reciter: reciter(for: ref))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
            .padding(16)
        }
        .navigationTitle("Haramain")
    }

    private func reciter(for ref: ReciterRef) -> Reciter {
        app.reciterOrPlaceholder(slug: ref.slug, name: ref.name)
    }
}
