import SwiftUI

@main
struct AIHedgeFundApp: App {
    @StateObject private var appViewModel = AppViewModel()
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appViewModel)
                .preferredColorScheme(isDarkMode ? .dark : .light)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1200, height: 800)
        
        #if os(macOS)
        Settings {
            SettingsView()
                .environmentObject(appViewModel)
                .preferredColorScheme(isDarkMode ? .dark : .light)
        }
        #endif
    }
}
