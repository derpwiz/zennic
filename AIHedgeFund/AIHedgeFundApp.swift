import SwiftUI

@main
struct AIHedgeFundApp: App {
    @StateObject private var appViewModel = AppViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appViewModel)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1200, height: 800)
        
        #if os(macOS)
        Settings {
            SettingsView()
                .environmentObject(appViewModel)
        }
        #endif
    }
}
