import SwiftUI

struct SidebarView: View {
    @Binding var selection: SidebarItem?

    var body: some View {
        List(selection: $selection) {
            Section("Jelajahi") {
                ForEach([SidebarItem.reciters, .haramain, .reading]) { item in
                    Label(item.title, systemImage: item.systemImage).tag(item)
                }
            }
            Section("Koleksi Saya") {
                ForEach([SidebarItem.favorites, .starred, .history, .downloads]) { item in
                    Label(item.title, systemImage: item.systemImage).tag(item)
                }
            }
            Section {
                ForEach([SidebarItem.settings, .about]) { item in
                    Label(item.title, systemImage: item.systemImage).tag(item)
                }
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("Murottal")
    }
}
