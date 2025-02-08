import Cocoa
import SwiftUI
import UI

class SceneDelegate: NSObject, NSWindowDelegate {
    weak var coordinator: AppCoordinator?
    var window: NSWindow?

    func setupMainWindow() {
        print("SceneDelegate setupMainWindow called")
        guard let coordinator = coordinator else {
            print("Coordinator is nil")
            return
        }
        
        let contentView = MainView().environmentObject(coordinator.appState)
        print("ContentView created")
        
        window = NSWindow(
            contentRect: NSRect(x: 100, y: 100, width: 1000, height: 700),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered, defer: false)
        print("Window created")
        
        window?.center()
        window?.setFrameAutosaveName("Main Window")
        window?.contentView = NSHostingView(rootView: contentView)
        window?.makeKeyAndOrderFront(nil)
        window?.delegate = self
        print("Window configured and displayed")
    }

    func windowWillClose(_ notification: Notification) {
        print("Window will close")
        // Handle window closing if needed
    }
}
