import SwiftUI
import DataIntegration
import Core
import CodeEditorInterface
import CodeEditor

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Initialize the CodeEditor implementation
        CodeEditor.CodeEditorFactory.initialize()
        print("Application did finish launching")
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        print("Application will terminate")
    }
}

@main
struct ZennicApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    private var appState = Core.appState
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
        }
    }
}
