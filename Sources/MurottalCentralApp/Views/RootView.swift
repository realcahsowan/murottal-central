import MurottalCentralCore
import SwiftUI

struct RootView: View {
    @Environment(AppState.self) private var app

    @State private var path = NavigationPath()

    var body: some View {
        @Bindable var app = app

        VStack(spacing: 0) {
            NavigationSplitView {
                SidebarView(selection: $app.selection)
                    .navigationSplitViewColumnWidth(min: 190, ideal: 215, max: 270)
            } detail: {
                NavigationStack(path: $path) {
                    detailContent
                        .navigationDestination(for: Route.self) { route in
                            switch route {
                            case let .reciter(reciter):
                                ReciterDetailView(reciter: reciter)
                            case let .surah(surah):
                                SurahDetailView(surah: surah)
                            case let .juz(juz):
                                JuzDetailView(juz: juz)
                            case let .reading(scope):
                                ReadingView(scope: scope)
                            }
                        }
                }
            }

            Divider()
            PlayerBar()
        }
        .onChange(of: app.selection) { _, _ in
            path = NavigationPath()
        }
    }

    @ViewBuilder
    private var detailContent: some View {
        switch app.selection ?? .reciters {
        case .reciters: ReciterGridView()
        case .surahs: SurahListView()
        case .juz: JuzListView()
        case .haramain: HaramainView()
        case .reading: ReadingHomeView()
        case .search: SearchView()
        case .favorites: FavoritesView()
        case .starred: StarredRecitersView()
        case .history: HistoryView()
        case .downloads: DownloadsView()
        case .settings: SettingsView()
        case .about: AboutView()
        }
    }
}
