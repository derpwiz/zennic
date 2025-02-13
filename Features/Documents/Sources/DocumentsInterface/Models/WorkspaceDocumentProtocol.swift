//
//  WorkspaceDocumentProtocol.swift
//  DocumentsInterface
//
//  Created by Claude on 2/11/25.
//

import Foundation
import SwiftUI
import Combine

/// Protocol defining the interface for workspace documents.
public protocol WorkspaceDocumentProtocol: AnyObject, ObservableObject {
    /// The currently selected feature in the workspace.
    var selectedFeature: String? { get set }
    
    /// The file manager for the workspace.
    var workspaceFileManager: CEWorkspaceFileManager? { get }
    
    /// Get a value from the workspace state.
    /// - Parameter key: The key to get the value for.
    /// - Returns: The value if it exists, nil otherwise.
    func getFromWorkspaceState(_ key: WorkspaceStateKey) -> Any?

    /// Add a value to the workspace state.
    /// - Parameters:
    ///   - key: The key to store the value under.
    ///   - value: The value to store. If nil, removes the value.
    func addToWorkspaceState(key: WorkspaceStateKey, value: Any?)
}

/// File manager for workspace files.
public class CEWorkspaceFileManager: ObservableObject {
    /// The root URL of the workspace.
    public let folderUrl: URL
    
    /// Initialize a new workspace file manager.
    /// - Parameter folderUrl: The root URL of the workspace.
    /// - Parameter ignoredFilesAndFolders: Set of file/folder names to ignore.
    public init(folderUrl: URL, ignoredFilesAndFolders: Set<String>) {
        self.folderUrl = folderUrl
    }
}
