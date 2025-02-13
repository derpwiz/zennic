//
//  EditorManager.swift
//  Editor
//
//  Created by Claude on 2/11/25.
//

import Foundation
import SwiftUI
import DocumentsInterface

/// Manages the editor layout and state.
public final class EditorManager: ObservableObject {
    /// The complete editor layout.
    @Published public var editorLayout: EditorLayout
    
    /// The currently active editor.
    public var activeEditor: Editor? {
        switch editorLayout {
        case .one(let editor):
            return editor
        case .horizontal(let data), .vertical(let data):
            // Get first editor from layout
            return data.editorLayouts.first.flatMap { layout in
                if case .one(let editor) = layout {
                    return editor
                }
                return nil
            }
        }
    }

    public init() {
        let tab = Editor()
        self.editorLayout = .horizontal(.init(.horizontal, editorLayouts: [.one(tab)]))
    }

    // MARK: - State Restoration

    /// Restore state from workspace document.
    /// - Parameter workspace: The workspace document.
    public func restoreFromState(_ workspace: any WorkspaceDocumentProtocol) {
        // TODO: Implement state restoration
    }

    /// Save state to workspace document.
    /// - Parameter workspace: The workspace document.
    public func saveRestorationState(_ workspace: any WorkspaceDocumentProtocol) {
        // TODO: Implement state saving
    }

    // MARK: - File Management

    /// Get all open files in the editor layout.
    /// - Returns: Array of open files.
    public func gatherOpenFiles() -> [CEWorkspaceFile] {
        switch editorLayout {
        case .one(let editor):
            return editor.tabs.map(\.file)
        case .horizontal(let data), .vertical(let data):
            return data.editorLayouts.flatMap { layout -> [CEWorkspaceFile] in
                switch layout {
                case .one(let editor):
                    return editor.tabs.map(\.file)
                case .horizontal(let nestedData), .vertical(let nestedData):
                    return nestedData.editorLayouts.flatMap { nestedLayout -> [CEWorkspaceFile] in
                        if case .one(let editor) = nestedLayout {
                            return editor.tabs.map(\.file)
                        }
                        return []
                    }
                }
            }
        }
    }

    /// Open a file in a new tab.
    /// - Parameter item: The file to open.
    public func openTab(item: CEWorkspaceFile) {
        activeEditor?.openTab(file: item)
    }
}
