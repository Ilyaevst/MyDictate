import SwiftUI

@main
struct NewMyDictateApp: App {
    @StateObject private var store = AppStore()
    @AppStorage("appearance") private var appearanceRaw = AppearancePreference.system.rawValue

    private var preferredColorScheme: ColorScheme? {
        switch AppearancePreference(rawValue: appearanceRaw) ?? .system {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }

    var body: some Scene {
        WindowGroup("New MyDictate") {
            RootView()
                .environmentObject(store)
                .preferredColorScheme(preferredColorScheme)
                .frame(minWidth: 980, minHeight: 650)
        }
        .defaultSize(width: 1180, height: 760)
        .windowResizability(.contentMinSize)
        .windowToolbarStyle(.unifiedCompact)
        .commands {
            CommandGroup(after: .appInfo) {
                Button("Открыть папку данных") {
                    NSWorkspace.shared.open(store.dataDirectory)
                }
            }
            CommandMenu("Диктовка") {
                Button("Показать индикатор") {
                    store.beginDictationPreview()
                }
                .keyboardShortcut("d", modifiers: [.command, .shift])

                Divider()

                ForEach(store.modes) { mode in
                    Button(mode.name) {
                        store.selectMode(mode.id)
                    }
                }
            }
        }
    }
}
