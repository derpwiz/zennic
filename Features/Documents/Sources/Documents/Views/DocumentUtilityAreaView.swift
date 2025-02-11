//
//  DocumentUtilityAreaView.swift
//  Documents
//
//  Created by Claude on 2/11/25.
//

import SwiftUI
import AppKit
import UtilityArea
import TerminalEmulator

/// A simplified utility area view that uses UtilityArea module components
struct DocumentUtilityAreaView: View {
    @EnvironmentObject private var viewModel: UtilityAreaViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            if let selectedTab = viewModel.selectedTab {
                switch selectedTab {
                case .terminal:
                    if let terminal = viewModel.terminals.first {
                        TerminalHostingView(terminalId: terminal.id)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        Text("No terminal available")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                case .output:
                    Text("Output")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                case .debug:
                    Text("Debug")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            } else {
                Text("No Tab Selected")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(.background)
    }
}

/// A container NSView that hosts a TerminalView
private final class TerminalContainerView: NSView {
    let terminalView: TerminalView
    
    init(terminalView: TerminalView) {
        self.terminalView = terminalView
        super.init(frame: NSRect(x: 0, y: 0, width: 100, height: 100))
        
        // Configure the container
        wantsLayer = true
        layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
        
        // Add the terminal view as a child
        addSubview(terminalView)
        
        // Set up constraints
        terminalView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            terminalView.leadingAnchor.constraint(equalTo: leadingAnchor),
            terminalView.trailingAnchor.constraint(equalTo: trailingAnchor),
            terminalView.topAnchor.constraint(equalTo: topAnchor),
            terminalView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// A SwiftUI wrapper view for TerminalView
private struct TerminalHostingView: View {
    let terminalId: UUID
    
    var body: some View {
        TerminalWrapper(terminalId: terminalId)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// NSViewRepresentable wrapper for TerminalView
private struct TerminalWrapper: NSViewRepresentable {
    let terminalId: UUID
    
    func makeNSView(context: Context) -> NSView {
        if let terminalView = TerminalCache.shared.getTerminalView(terminalId) {
            return TerminalContainerView(terminalView: terminalView)
        } else {
            let label = NSTextField(labelWithAttributedString: NSAttributedString(string: "Terminal not found"))
            label.alignment = .center
            label.isEditable = false
            label.isSelectable = false
            label.drawsBackground = false
            label.isBezeled = false
            return label
        }
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        // Update the terminal view if needed
    }
}

#if DEBUG
struct DocumentUtilityAreaView_Previews: PreviewProvider {
    static var previews: some View {
        DocumentUtilityAreaView()
            .environmentObject(UtilityAreaViewModel())
    }
}
#endif
