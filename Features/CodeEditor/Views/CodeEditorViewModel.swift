import SwiftUI
import Features.Shared.Models
import Features.Shared.Services

enum CodeEditorError: Error {
    case noFileSelected
}

class CodeEditorViewModel: ObservableObject {
    @Published var code: String
    @Published var language: CodeLanguage
    @Published var output: String
    @Published var autoCompleteSuggestions: [String]
    @Published var showAutoComplete: Bool
    @Published var codeHistory: [String]
    @Published var selectedFile: String?
    @Published var error: Error?
    
    private let gitService: GitService
    
    init(code: String, language: CodeLanguage, gitService: GitService = GitService.shared) {
        self.code = code
        self.language = language
        self.output = ""
        self.autoCompleteSuggestions = []
        self.showAutoComplete = false
        self.codeHistory = []
        self.selectedFile = nil
        self.gitService = gitService
    }
    
    func loadFile(_ fileName: String) throws {
        code = try gitService.readFile(name: fileName)
        selectedFile = fileName
        language = CodeLanguage(rawValue: URL(fileURLWithPath: fileName).pathExtension) ?? .python
    }
    
    func saveCurrentFile() throws {
        guard let fileName = selectedFile else { throw CodeEditorError.noFileSelected }
        try gitService.updateFile(name: fileName, content: code)
    }
}
