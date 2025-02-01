import SwiftUI
import Cocoa
import Core

class AppCoordinator: ObservableObject {
    @Published var window: NSWindow?
    @Published var appState: Core.AppState
    
    init(appState: Core.AppState) {
        self.appState = appState
    }
    
    func createMainWindow() {
        let contentView = MainView().environmentObject(appState)
        
        let mainWindow = NSWindow(
            contentRect: NSRect(x: 100, y: 100, width: 1000, height: 700),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        mainWindow.title = "Zennic"
        mainWindow.center()
        mainWindow.setFrameAutosaveName("Main Window")
        mainWindow.contentView = NSHostingView(rootView: contentView)
        mainWindow.makeKeyAndOrderFront(nil)
        
        self.window = mainWindow
    }
}
