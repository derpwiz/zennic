//
//  SearchPanel.swift
//  zennic
//

import AppKit
import SwiftUI
import DocumentsInterface

class SearchPanel: NSPanel {
    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 400),
            styleMask: [.titled, .closable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        self.isFloatingPanel = true
        self.titlebarAppearsTransparent = true
        self.titleVisibility = .hidden
        self.isMovableByWindowBackground = true
        self.backgroundColor = .clear
        self.hasShadow = true
        self.level = .floating
        self.collectionBehavior = [.transient, .ignoresCycle]
        self.animationBehavior = .utilityWindow
        
        // Center the panel on screen
        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let panelFrame = self.frame
            let x = screenFrame.midX - panelFrame.width / 2
            let y = screenFrame.midY - panelFrame.height / 2
            self.setFrameOrigin(NSPoint(x: x, y: y))
        }
    }
    
    override var canBecomeKey: Bool {
        return true
    }
    
    override var canBecomeMain: Bool {
        return true
    }
}

// MARK: - Search Panel Content Views

struct QuickActionsView: View {
    @ObservedObject var state: CommandsPaletteState
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Search field
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search commands...", text: $state.searchText)
                    .textFieldStyle(.plain)
                if !state.searchText.isEmpty {
                    Button {
                        state.searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(8)
            
            Divider()
            
            // Results list
            List(selection: $state.selectedCommand) {
                // TODO: Implement command list
                Text("Command Palette")
            }
            .listStyle(.plain)
        }
        .background(VisualEffectView(material: .menu, blendingMode: .behindWindow))
    }
}

struct OpenQuicklyView<Document: WorkspaceDocumentProtocol>: View {
    @ObservedObject var state: OpenQuicklyViewModel
    @ObservedObject var workspace: Document
    let onDismiss: () -> Void
    let openFile: (CEWorkspaceFile) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Search field
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search files...", text: $state.searchText)
                    .textFieldStyle(.plain)
                if !state.searchText.isEmpty {
                    Button {
                        state.searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(8)
            
            Divider()
            
            // Results list
            List(selection: $state.selectedFile) {
                // TODO: Implement file list
                Text("Quick Open")
            }
            .listStyle(.plain)
        }
        .background(VisualEffectView(material: .menu, blendingMode: .behindWindow))
    }
}

// MARK: - Visual Effect View

struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}
