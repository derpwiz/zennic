//
//  EditorInstance.swift
//  Editor
//
//  Created by Claude on 2/11/25.
//

import Foundation
import DocumentsInterface

/// Represents a tab in the editor.
public struct EditorInstance: Identifiable, Hashable {
    /// The file associated with this tab.
    public let file: CEWorkspaceFile

    /// The unique identifier for this tab.
    public var id: String { file.id }

    public init(file: CEWorkspaceFile) {
        self.file = file
    }

    public static func == (lhs: EditorInstance, rhs: EditorInstance) -> Bool {
        lhs.file == rhs.file
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(file)
    }
}
