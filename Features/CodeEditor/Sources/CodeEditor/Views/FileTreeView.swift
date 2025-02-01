import SwiftUI
import Shared
import Core

public struct FileItem: Identifiable, Hashable {
    public let id = UUID()
    public let name: String
    public var children: [FileItem]? = nil
    public var isDirectory: Bool { children != nil }
    
    public init(name: String, children: [FileItem]? = nil) {
        self.name = name
        self.children = children
    }
    
    public static func == (lhs: FileItem, rhs: FileItem) -> Bool {
        lhs.name == rhs.name
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
}

public struct AlertItem: Identifiable {
    public let id = UUID()
    public let error: Error
    
    public init(error: Error) {
        self.error = error
    }
}

public class FileTreeViewModel: ObservableObject {
    @Published public var items: [FileItem] = []
    @Published public var error: AlertItem?
    @Published public var selectedItem: FileItem?
    private let gitService: GitService
    
    public init(gitService: GitService = GitService.shared) {
        self.gitService = gitService
    }
    
    public func loadFiles() {
        do {
            let files = try gitService.listFiles()
            items = files.map { FileItem(name: $0) }
            // Update selection if needed
            if let currentFile = selectedItem?.name,
               !items.contains(where: { $0.name == currentFile }) {
                selectedItem = nil
            }
        } catch {
            self.error = AlertItem(error: error)
        }
    }
    
    public func createFile(name: String, content: String) {
        do {
            try gitService.createFile(name: name, content: content)
            loadFiles()
        } catch {
            self.error = AlertItem(error: error)
        }
    }
    
    public func deleteFile(name: String) {
        do {
            try gitService.deleteFile(name: name)
            if selectedItem?.name == name {
                selectedItem = nil
            }
            loadFiles()
        } catch {
            self.error = AlertItem(error: error)
        }
    }
}

public struct FileTreeView: View {
    @StateObject private var viewModel = FileTreeViewModel()
    @EnvironmentObject private var codeEditorViewModel: CodeEditorViewModel
    @State private var showingCreateFile = false
    @State private var newFileName = ""
    @State private var newFileContent = ""
    
    public init() {}
    
    private func createFile(name: String, content: String) {
        viewModel.createFile(name: name, content: content)
    }
    
    public var body: some View {
        List(viewModel.items, selection: $viewModel.selectedItem) { item in
            HStack {
                Image(systemName: item.isDirectory ? "folder" : "doc.text")
                Text(item.name)
            }
            .tag(item)
            .contextMenu {
                Button("Delete") {
                    viewModel.deleteFile(name: item.name)
                }
            }
        }
        .onChange(of: viewModel.selectedItem) { item in
            if let item = item {
                do {
                    try codeEditorViewModel.loadFile(item.name)
                } catch {
                    viewModel.error = AlertItem(error: error)
                }
            }
        }
        .onChange(of: codeEditorViewModel.selectedFile) { fileName in
            if let fileName = fileName {
                viewModel.loadFiles()
                viewModel.selectedItem = viewModel.items.first { $0.name == fileName }
            }
        }
        .navigationTitle("Scripts")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showingCreateFile = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingCreateFile) {
            CreateFileView(isPresented: $showingCreateFile, onCreate: createFile)
        }
        .onAppear {
            viewModel.loadFiles()
        }
        .alert(item: $viewModel.error) { item in
            Alert(title: Text("Error"), message: Text(item.error.localizedDescription), dismissButton: .default(Text("OK")))
        }
    }
}

struct CreateFileView: View {
    @Binding var isPresented: Bool
    let onCreate: (String, String) -> Void
    @State private var fileName = ""
    @State private var fileContent = ""
    
    var body: some View {
        NavigationView {
            Form {
                TextField("File Name", text: $fileName)
                TextEditor(text: $fileContent)
                    .frame(height: 200)
            }
            .navigationTitle("Create New File")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        onCreate(fileName, fileContent)
                        isPresented = false
                    }
                    .disabled(fileName.isEmpty)
                }
            }
        }
    }
}

struct FileTreeView_Previews: PreviewProvider {
    static var previews: some View {
        FileTreeView()
            .environmentObject(CodeEditorViewModel(code: "", language: CodeLanguage.python))
    }
}
