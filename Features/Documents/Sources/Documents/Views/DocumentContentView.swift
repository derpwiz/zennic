//
//  DocumentContentView.swift
//  Documents
//
//  Created by Claude on 2/11/25.
//

import SwiftUI
import Core
import Editor
import UtilityArea
import CodeEditor
import CodeEditorInterface
import DocumentsInterface

/// A simple container view that provides the basic layout structure
/// without depending on UI module implementation details
public struct DocumentContentView<Document: WorkspaceDocumentProtocol>: View {
    @ObservedObject private var workspace: Document
    @EnvironmentObject private var editorManager: EditorManager
    @EnvironmentObject private var statusBarViewModel: StatusBarViewModel
    @EnvironmentObject private var utilityAreaModel: UtilityAreaViewModel
    
    public init(workspace: Document) {
        self.workspace = workspace
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Main content area
            if let fileManager = workspace.workspaceFileManager {
                CodeEditorFactory.makeEditor(workspacePath: fileManager.folderUrl.path)
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "folder.badge.plus")
                        .font(.system(size: 48))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(.secondary)
                    Text("Please select a workspace path")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
            }
            
            // Utility area
            if !utilityAreaModel.isCollapsed {
                Divider()
                DocumentUtilityAreaView()
                    .environmentObject(utilityAreaModel)
                    .frame(height: 300)
            }
        }
    }
}

#if DEBUG
struct DocumentContentView_Previews: PreviewProvider {
    static var previews: some View {
        DocumentContentView(workspace: WorkspaceDocument())
            .environmentObject(EditorManager())
            .environmentObject(StatusBarViewModel())
            .environmentObject(UtilityAreaViewModel())
    }
}
#endif
