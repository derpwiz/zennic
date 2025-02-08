import SwiftUI

public protocol CodeEditor {
    var workspacePath: String { get }
    var selectedFile: String? { get set }
    var fileContent: String { get set }
    
    func loadFile(_ path: String) async throws
    func saveFile() async throws
}

public protocol CodeEditorViewModel: ObservableObject {
    var editor: CodeEditor { get }
    var selectedFile: String? { get set }
    var fileContent: String { get set }
    
    func loadFile(_ path: String) async
    func saveFile() async
}
