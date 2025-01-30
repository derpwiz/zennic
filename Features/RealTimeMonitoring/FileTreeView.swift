import SwiftUI

struct FileItem: Identifiable {
    let id = UUID()
    let name: String
    var children: [FileItem]? = nil
    var isDirectory: Bool { children != nil }
}

class FileTreeViewModel: ObservableObject {
    @Published var items: [FileItem] = []
    private let gitService = GitService.shared
    
    func loadFiles() {
        do {
            let files = try gitService.listFiles()
            items = files.map { FileItem(name: $0) }
        } catch {
            print("Error loading files: \(error)")
        }
    }
    
    func createFile(name: String, content: String) {
        do {
            try gitService.createFile(name: name, content: content)
            loadFiles()
        } catch {
            print("Error creating file: \(error)")
        }
    }
    
    func deleteFile(name: String) {
        do {
            try gitService.deleteFile(name: name)
            loadFiles()
        } catch {
            print("Error deleting file: \(error)")
        }
    }
}

struct FileTreeView: View {
    @StateObject private var viewModel = FileTreeViewModel()
    @State private var selectedFile: String?
    @State private var showingCreateFile = false
    @State private var newFileName = ""
    @State private var newFileContent = ""
    
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
                    viewModel.deleteFile(name: item.name)
                }
            }
        }
        .navigationTitle("Scripts")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingCreateFile = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingCreateFile) {
            CreateFileView(isPresented: $showingCreateFile, onCreate: { name, content in
                viewModel.createFile(name: name, content: content)
            })
        }
        .onAppear {
            viewModel.loadFiles()
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
            .navigationBarItems(
                leading: Button("Cancel") { isPresented = false },
                trailing: Button("Create") {
                    onCreate(fileName, fileContent)
                    isPresented = false
                }
                .disabled(fileName.isEmpty)
            )
        }
    }
}

struct FileTreeView_Previews: PreviewProvider {
    static var previews: some View {
        FileTreeView()
    }
}
