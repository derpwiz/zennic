import SwiftUI
import DataIntegration
import Core
import CodeEditorInterface
import CodeEditor
import UniformTypeIdentifiers

extension UTType {
    static var zennicWorkspace: UTType {
        UTType(exportedAs: "com.zennic.workspace")
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Initialize the CodeEditor implementation
        CodeEditorFactory.initialize()
        print("Application did finish launching")
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        print("Application will terminate")
    }
}

@main
struct ZennicApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    private var appState = AppState.shared
    
    var body: some Scene {
        DocumentGroup(viewing: WorkspaceDocument.self) { file in
            ContentView()
                .environmentObject(appState)
                .environmentObject(file.document)
        }
    }
}
