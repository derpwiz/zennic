import SwiftUI
import AppKit
import UniformTypeIdentifiers

/// Represents a tab in the editor
public struct EditorTab: Identifiable, Hashable {
    /// The unique identifier for the tab
    public let id: EditorTabID
    
    /// The display name of the tab
    public let name: String
    
    /// The file path if this tab represents a file
    public let path: String?
    
    /// Whether this tab has unsaved changes
    public var hasChanges: Bool
    
    /// The icon for the file type
    public var icon: NSImage {
        if let path = path {
            return NSWorkspace.shared.icon(forFile: path)
        }
        return NSWorkspace.shared.icon(for: UTType.plainText)
    }
    
    /// The color for the file icon
    public var iconColor: Color {
        if let path = path {
            let ext = (path as NSString).pathExtension.lowercased()
            switch ext {
            case "swift": return .orange
            case "js", "jsx": return .yellow
            case "ts", "tsx": return .blue
            case "css": return .purple
            case "html": return .red
            default: return .secondary
            }
        }
        return .secondary
    }
    
    public init(id: EditorTabID, name: String, path: String? = nil, hasChanges: Bool = false) {
        self.id = id
        self.name = name
        self.path = path
        self.hasChanges = hasChanges
    }
    
    public static func == (lhs: EditorTab, rhs: EditorTab) -> Bool {
        lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
