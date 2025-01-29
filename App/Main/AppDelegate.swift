import SwiftUI
import DataIntegration

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        print("Application did finish launching")
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        print("Application will terminate")
    }
}

@main
struct ZennicApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
        }
    }
}
