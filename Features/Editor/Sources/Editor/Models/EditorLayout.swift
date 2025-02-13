//
//  EditorLayout.swift
//  Editor
//
//  Created by Claude on 2/11/25.
//

import Foundation
import SwiftUI

/// Represents the layout of editors in a split view.
public enum EditorLayout: Equatable {
    case one(Editor)
    case horizontal(SplitViewData)
    case vertical(SplitViewData)

    /// Find an editor with a specific ID.
    /// - Parameter id: The ID to search for.
    /// - Returns: The editor with the matching ID, if found.
    public func findEditor(with id: UUID) -> Editor? {
        switch self {
        case .one(let editor):
            return editor.id == id ? editor : nil
        case .horizontal(let data), .vertical(let data):
            return data.findEditor(with: id)
        }
    }

    /// Find some editor, excluding a specific one.
    /// - Parameter editor: The editor to exclude from the search.
    /// - Returns: Some editor that isn't the excluded one.
    public func findSomeEditor(except editor: Editor) -> Editor? {
        switch self {
        case .one(let someEditor):
            return someEditor == editor ? nil : someEditor
        case .horizontal(let data), .vertical(let data):
            return data.findSomeEditor(except: editor)
        }
    }
}

/// Data for a split view layout.
public final class SplitViewData: ObservableObject {
    /// The orientation of the split view.
    public let orientation: SplitOrientation

    /// The layouts contained in this split view.
    @Published public var editorLayouts: [EditorLayout]

    public init(_ orientation: SplitOrientation, editorLayouts: [EditorLayout]) {
        self.orientation = orientation
        self.editorLayouts = editorLayouts
    }

    /// Find an editor with a specific ID.
    /// - Parameter id: The ID to search for.
    /// - Returns: The editor with the matching ID, if found.
    public func findEditor(with id: UUID) -> Editor? {
        for layout in editorLayouts {
            if let editor = layout.findEditor(with: id) {
                return editor
            }
        }
        return nil
    }

    /// Find some editor, excluding a specific one.
    /// - Parameter editor: The editor to exclude from the search.
    /// - Returns: Some editor that isn't the excluded one.
    public func findSomeEditor(except editor: Editor) -> Editor? {
        for layout in editorLayouts {
            if let someEditor = layout.findSomeEditor(except: editor) {
                return someEditor
            }
        }
        return nil
    }

    /// Close an editor with a specific ID.
    /// - Parameter id: The ID of the editor to close.
    public func closeEditor(with id: UUID) {
        for (index, layout) in editorLayouts.enumerated() {
            switch layout {
            case .one(let editor) where editor.id == id:
                editorLayouts.remove(at: index)
            case .horizontal(let data), .vertical(let data):
                data.closeEditor(with: id)
            default:
                break
            }
        }
    }

    /// Get the editor layout for an editor with a specific ID.
    /// - Parameter id: The ID of the editor.
    /// - Returns: The editor layout containing the editor, if found.
    public func getEditorLayout(with id: UUID) -> EditorLayout? {
        for layout in editorLayouts {
            switch layout {
            case .one(let editor) where editor.id == id:
                return layout
            case .horizontal(let data), .vertical(let data):
                if data.findEditor(with: id) != nil {
                    return layout
                }
            default:
                break
            }
        }
        return nil
    }
}

/// The orientation of a split view.
public enum SplitOrientation {
    case horizontal
    case vertical
}

extension EditorLayout {
    public static func == (lhs: EditorLayout, rhs: EditorLayout) -> Bool {
        switch (lhs, rhs) {
        case (.one(let lEditor), .one(let rEditor)):
            return lEditor == rEditor
        case (.horizontal(let lData), .horizontal(let rData)):
            return lData === rData
        case (.vertical(let lData), .vertical(let rData)):
            return lData === rData
        default:
            return false
        }
    }
}
