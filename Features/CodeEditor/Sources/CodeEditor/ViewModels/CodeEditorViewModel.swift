import SwiftUI
import Shared
import Core

public enum CodeEditorError: LocalizedError {
    case noFileSelected
    case gitOperationFailed(String)
    
    public var errorDescription: String? {
        switch self {
        case .noFileSelected:
            return "No file is currently selected"
        case .gitOperationFailed(let message):
            return message
        }
    }
}

public class CodeEditorViewModel: ObservableObject {
    private let codeDirectory: URL
    @Published public var code: String
    @Published public var language: CodeLanguage {
        didSet {
            saveCurrentLanguage(language)
        }
    }
    @Published public var output: String
    @Published public var autoCompleteSuggestions: [String]
    @Published public var showAutoComplete: Bool
    @Published public var codeHistory: [String]
    @Published public var selectedFile: String?
    @Published public var error: Error?
    
    private let gitService: Core.GitServiceType
    private var fileCounter = 0
    
    public init(code: String, language: CodeLanguage, gitService: Core.GitServiceType = Core.shared) {
        self.code = code
        self.language = language
        self.output = ""
        self.autoCompleteSuggestions = []
        self.showAutoComplete = false
        self.codeHistory = []
        self.selectedFile = nil
        self.gitService = gitService
        self.codeDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("ZennicCode")
        
        saveCurrentLanguage(language)
    }
    
    private func saveCurrentLanguage(_ language: CodeLanguage) {
        UserDefaults.standard.set(language.rawValue, forKey: "currentLanguage")
    }
    
    public func loadFile(_ fileName: String) throws {
        do {
            code = try gitService.readFile(name: fileName)
            selectedFile = fileName
            language = CodeLanguage(rawValue: URL(fileURLWithPath: fileName).pathExtension) ?? .python
        } catch let error as Core.GitErrorType {
            throw CodeEditorError.gitOperationFailed(error.localizedDescription)
        }
    }
    
    public func getDefaultFileName() -> String {
        fileCounter += 1
        return "untitled\(fileCounter)"
    }
    
    public func createNewFile() {
        let fileExtension = language.rawValue.lowercased()
        selectedFile = "\(getDefaultFileName()).\(fileExtension)"
        code = ""
    }
    
    public func saveCurrentFile() throws {
        if selectedFile == nil {
            createNewFile()
        }
        
        guard let fileName = selectedFile else { throw CodeEditorError.noFileSelected }
        
        do {
            try gitService.updateFile(name: fileName, content: code)
            objectWillChange.send() // Notify observers of the change
        } catch let error as Core.GitErrorType {
            throw CodeEditorError.gitOperationFailed(error.localizedDescription)
        }
    }
}
