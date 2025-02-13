//
//  WorkspaceView.swift
//  zennic
//

import SwiftUI
import Editor              // For EditorManager
import UtilityArea        // For UtilityAreaViewModel
import CodeEditorInterface // For StatusBarViewModel
import DocumentsInterface  // For WorkspaceDocument
import UI                 // For UtilityAreaView

struct WorkspaceView<Document: WorkspaceDocumentProtocol>: View {
    @ObservedObject var workspace: Document
    @EnvironmentObject var editorManager: Editor.EditorManager
    @EnvironmentObject var statusBarViewModel: CodeEditorInterface.StatusBarViewModel
    @EnvironmentObject var utilityAreaModel: UtilityArea.UtilityAreaViewModel
    @EnvironmentObject var taskManager: TaskManager
    
    init(workspace: Document) {
        self.workspace = workspace
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Editor area
            EditorAreaView(workspace: workspace)
                .environmentObject(editorManager)
            
            // Status bar
            StatusBarView()
                .environmentObject(statusBarViewModel)
            
            // Utility area
            if !utilityAreaModel.isCollapsed {
                Divider()
                UtilityAreaView()
                    .environmentObject(utilityAreaModel)
                    .environmentObject(taskManager)
                    .frame(height: utilityAreaModel.height)
            }
        }
    }
}

struct EditorAreaView<Document: WorkspaceDocumentProtocol>: View {
    @ObservedObject var workspace: Document
    @EnvironmentObject var editorManager: Editor.EditorManager
    
    init(workspace: Document) {
        self.workspace = workspace
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Editor tabs
            EditorTabBarView()
                .environmentObject(editorManager)
            
            // Editor content
            if let editor = editorManager.activeEditor,
               let selectedTab = editor.selectedTab {
                EditorContentView(editor: selectedTab)
            } else {
                NoEditorView()
            }
        }
    }
}

struct EditorTabBarView: View {
    @EnvironmentObject var editorManager: Editor.EditorManager
    
    var body: some View {
        HStack {
            // TODO: Implement tab bar
            Text("Editor Tabs")
        }
        .frame(height: 28)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

struct EditorContentView: View {
    let editor: EditorInstance
    
    var body: some View {
        // TODO: Implement editor content
        Text("Editor Content")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct NoEditorView: View {
    var body: some View {
        VStack {
            Image(systemName: "doc.text")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text("No Editor")
                .font(.title2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct StatusBarView: View {
    @EnvironmentObject var statusBarViewModel: CodeEditorInterface.StatusBarViewModel
    
    var body: some View {
        HStack {
            // TODO: Implement status bar items
            Text("Status Bar")
        }
        .frame(height: 22)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

#Preview {
    WorkspaceView(workspace: WorkspaceDocument())
        .environmentObject(EditorManager())
        .environmentObject(StatusBarViewModel())
        .environmentObject(UtilityAreaViewModel())
        .environmentObject(TaskManager())
}
