import Foundation
import MurottalCentralCore
import SwiftUI

@main
struct MurottalCentralApp: App {

    @State private var appState = AppState()
    @State private var settings = AppSettings()

    init() {
        // Daftarkan font Qur'an yang dibundel sebelum view dirender.
        let registered = QuranFontRegistry.registerBundledFonts()

        if ProcessInfo.processInfo.environment["MUROTTAL_FONT_DEBUG"] == "1" {
            let message = """
            Font terdaftar: \(registered)
            Uthmani tersedia: \(QuranFontRegistry.isAvailable(.uthmani))
            IndoPak tersedia: \(QuranFontRegistry.isAvailable(.indopak))

            """
            FileHandle.standardError.write(Data(message.utf8))
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appState)
                .environment(settings)
                .preferredColorScheme(colorScheme)
                .frame(minWidth: 960, minHeight: 620)
                .task {
                    await appState.start()
                }
        }
        .windowStyle(.titleBar)
        .commands {
            CommandGroup(after: .newItem) {
                Button("Muat Ulang Katalog") {
                    Task { await appState.reloadCatalog() }
                }
                .keyboardShortcut("r", modifiers: [.command, .shift])
            }

            CommandGroup(after: .sidebar) {
                Divider()
                Button("Qari") { appState.selection = .reciters }
                    .keyboardShortcut("1", modifiers: .command)
                Button("Haramain") { appState.selection = .haramain }
                    .keyboardShortcut("2", modifiers: .command)
                Button("Baca") { appState.selection = .reading }
                    .keyboardShortcut("3", modifiers: .command)
                Button("Favorit") { appState.selection = .favorites }
                    .keyboardShortcut("4", modifiers: .command)
                Button("Unduhan") { appState.selection = .downloads }
                    .keyboardShortcut("5", modifiers: .command)
                Button("Pengaturan") { appState.selection = .settings }
                    .keyboardShortcut(",", modifiers: .command)
            }

            CommandMenu("Pemutaran") {
                Button("Putar / Jeda") { appState.player.togglePlayPause() }
                    .keyboardShortcut(.space, modifiers: [])
                    .disabled(appState.player.current == nil)

                Button("Trek Berikutnya") { appState.player.next() }
                    .keyboardShortcut(.rightArrow, modifiers: .command)
                    .disabled(appState.player.current == nil)

                Button("Trek Sebelumnya") { appState.player.previous() }
                    .keyboardShortcut(.leftArrow, modifiers: [.command])
                    .disabled(appState.player.current == nil)

                Divider()

                Button("Acak") { appState.player.toggleShuffle() }
                    .keyboardShortcut("s", modifiers: [.command, .shift])

                Button("Ulangi") { appState.player.cycleRepeatMode() }
                    .keyboardShortcut("l", modifiers: [.command, .shift])

                Divider()

                Menu("Sleep Timer") {
                    Button("Nonaktif") { appState.player.cancelSleepTimer() }
                        .disabled(appState.player.sleepTimerMode == .off)

                    Divider()

                    ForEach(AudioPlayer.sleepTimerPresets, id: \.self) { minutes in
                        Button("\(minutes) menit") {
                            appState.player.setSleepTimer(minutes: minutes)
                        }
                    }

                    Divider()

                    Button("Akhir trek ini") {
                        appState.player.setSleepTimerEndOfTrack()
                    }
                }
            }
        }
    }

    private var colorScheme: ColorScheme? {
        switch settings.theme {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}
