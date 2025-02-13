//
//  SearchViewModels.swift
//  zennic
//

import SwiftUI
import DocumentsInterface

final class CommandsPaletteState: ObservableObject {
    @Published var searchText: String = ""
    @Published var selectedCommand: String?
    @Published var commands: [String] = []
    
    init() {
        // TODO: Initialize with available commands
    }
    
    func reset() {
        searchText = ""
        selectedCommand = nil
    }
    
    func executeSelectedCommand() {
        guard let command = selectedCommand else { return }
        // TODO: Execute command
    }
}

final class OpenQuicklyViewModel<Document: WorkspaceDocumentProtocol>: ObservableObject {
    @Published var searchText: String = ""
    @Published var selectedFile: CEWorkspaceFile?
    @Published var files: [CEWorkspaceFile] = []
    
    private weak var workspace: Document?
    
    init(workspace: Document?) {
        self.workspace = workspace
        // TODO: Initialize with workspace files
    }
    
    func updateFiles() {
        // TODO: Update files based on workspace
    }
    
    func filterFiles() {
        // TODO: Filter files based on search text
    }
}
