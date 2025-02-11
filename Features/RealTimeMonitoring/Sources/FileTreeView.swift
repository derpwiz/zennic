import SwiftUI
import Core
import AppKit
import Documents

struct FileItem: Identifiable {
    let id = UUID()
    let name: String
    var children: [FileItem]? = nil
    var isDirectory: Bool { children != nil }
}

class FileTreeViewModel: ObservableObject {
    @Published var items: [FileItem] = []
    private var gitService: Core.GitServiceType?
    
    private func initializeGitService(workspace: WorkspaceDocument) {
        if let fileManager = workspace.workspaceFileManager {
            gitService = try? Core.GitServiceType(path: fileManager.folderUrl.path)
        }
    }
    
    func loadFiles(workspace: WorkspaceDocument) {
        initializeGitService(workspace: workspace)
        do {
            guard let gitService = gitService else { return }
            let files = try gitService.listFiles()
            items = files.map { FileItem(name: $0) }
        } catch {
            print("Error loading files: \(error)")
        }
    }
    
    func createFile(name: String, content: String, workspace: WorkspaceDocument) {
        initializeGitService(workspace: workspace)
        do {
            guard let gitService = gitService else { return }
            try gitService.createFile(name: name, content: content)
            loadFiles(workspace: workspace)
        } catch {
            print("Error creating file: \(error)")
        }
    }
    
    func deleteFile(name: String, workspace: WorkspaceDocument) {
        initializeGitService(workspace: workspace)
        do {
            guard let gitService = gitService else { return }
            try gitService.deleteFile(name: name)
            loadFiles(workspace: workspace)
        } catch {
            print("Error deleting file: \(error)")
        }
    }
}

struct FileTreeView: View {
    @StateObject private var viewModel = FileTreeViewModel()
    @EnvironmentObject private var workspace: WorkspaceDocument
    @State private var selectedFile: String? = nil
    @State private var showingCreateFile = false
    
    var body: some View {
        List(viewModel.items) { item in
            HStack {
                Image(systemName: item.isDirectory ? "folder" : "doc.text")
                Text(item.name)
            }
            .onTapGesture {
                selectedFile = item.name
            }
            .contextMenu {
                Button("Delete") {
                    viewModel.deleteFile(name: item.name, workspace: workspace)
                }
            }
        }
        .navigationTitle("Scripts")
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button(action: { showingCreateFile = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingCreateFile) {
            CreateFileView(isPresented: $showingCreateFile, onCreate: { name, content in
                viewModel.createFile(name: name, content: content, workspace: workspace)
            })
        }
        .onAppear {
            viewModel.loadFiles(workspace: workspace)
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

#if DEBUG
struct FileTreeView_Previews: PreviewProvider {
    static var previews: some View {
        let workspace = WorkspaceDocument()
        return FileTreeView()
            .environmentObject(workspace)
    }
}
#endif
