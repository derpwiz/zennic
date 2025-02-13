//
//  CEWorkspaceFile.swift
//  DocumentsInterface
//
//  Created by Claude on 2/11/25.
//

import Foundation
import AppKit

/// Represents a file in the workspace.
public final class CEWorkspaceFile: Identifiable, Hashable {
    private let fileRef: CEWorkspaceFileRef
    
    /// The parent file, if any.
    public weak var parent: CEWorkspaceFile?
    
    /// The file document, if loaded.
    public var fileDocument: NSDocument?
    
    /// The unique identifier for this file.
    public var id: String { fileRef.id.uuidString }
    
    /// The URL of the file.
    public var url: URL { fileRef.url }
    
    /// The resolved URL (following symlinks).
    public var resolvedURL: URL { fileRef.resolvedURL }
    
    /// Whether this file is a folder.
    public var isFolder: Bool { fileRef.isFolder }
    
    public init(url: URL) {
        self.fileRef = CEWorkspaceFileRef(url: url)
    }
    
    public static func == (lhs: CEWorkspaceFile, rhs: CEWorkspaceFile) -> Bool {
        lhs.fileRef.id == rhs.fileRef.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(fileRef.id)
    }
}
