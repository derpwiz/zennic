//
//  CEWorkspaceFileRef.swift
//  DocumentsInterface
//
//  Created by Claude on 2/11/25.
//

import Foundation

/// Represents a file reference in the workspace.
public struct CEWorkspaceFileRef: Identifiable, Hashable {
    /// The unique identifier for this file.
    public let id = UUID()
    
    /// The URL of the file.
    public let url: URL
    
    /// The resolved URL (following symlinks).
    public var resolvedURL: URL {
        (try? url.resolvingSymlinksInPath()) ?? url
    }
    
    /// Whether this file is a folder.
    public var isFolder: Bool {
        (try? resolvedURL.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
    }
    
    public init(url: URL) {
        self.url = url
    }
}
