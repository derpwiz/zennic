import SwiftUI
import Core
import Shared
import CodeEditorInterface

public class DefaultCodeEditor: CodeEditor {
    public let workspacePath: String
    public var selectedFile: String?
    public var fileContent: String = ""
    
    public init(workspacePath: String) {
        self.workspacePath = workspacePath
    }
    
    public func loadFile(_ path: String) async throws {
        // TODO: Implement file loading
        fileContent = ""
    }
    
    public func saveFile() async throws {
        // TODO: Implement file saving
    }
}

public class CodeEditorViewModel: CodeEditorViewModelProtocol {
    public var editor: CodeEditor
    @Published public var selectedFile: String?
    @Published public var fileContent: String = ""
    @Published public var cursorLine: Int = 0
    @Published public var cursorColumn: Int = 0
    @Published public var characterOffset: Int = 0
    @Published public var selectedLength: Int = 0
    @Published public var selectedLines: Int = 0
    @Published public var fileSize: Int?
    @Published public var files: [String] = []
    @Published public var error: String?
    
    public init(workspacePath: String) {
        self.editor = DefaultCodeEditor(workspacePath: workspacePath)
        loadFiles()
    }
    
    private func loadFiles() {
        // TODO: Implement file loading from workspace
        files = []
    }
    
    public func loadFile(_ path: String) async {
        error = nil
        do {
            try await editor.loadFile(path)
        } catch {
            self.error = error.localizedDescription
            return
        }
        selectedFile = path
        fileContent = editor.fileContent
    }
    
    public func saveFile() async {
        error = nil
        editor.fileContent = fileContent
        do {
            try await editor.saveFile()
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    public func scanDirectory(path: String) {
        // TODO: Implement directory scanning
    }
    
    public func initializeGit() {
        // TODO: Implement Git initialization
        error = nil
    }
    
    /// Updates the status bar model with the current state
    public func updateStatusBar() -> CodeEditorInterface.StatusBarModel {
        CodeEditorInterface.StatusBarModel(
            fileSize: fileSize,
            line: cursorLine,
            column: cursorColumn,
            characterOffset: characterOffset,
            selectedLength: selectedLength,
            selectedLines: selectedLines
        )
    }
}
