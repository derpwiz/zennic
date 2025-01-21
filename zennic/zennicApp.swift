/// Zennic - A SwiftUI-based trading application that provides portfolio management,
/// market analysis, and trading capabilities through the Alpaca API.
import SwiftUI

@main
struct zennicApp: App {
    /// The main view model that manages the application's state and business logic
    @StateObject private var appViewModel = AppViewModel()
    
    /// User preference for dark/light mode, persisted across app launches
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
        // Settings view available only on macOS platform
        Settings {
            SettingsView()
                .environmentObject(appViewModel)
                .preferredColorScheme(isDarkMode ? .dark : .light)
        }
        #endif
    }
}
