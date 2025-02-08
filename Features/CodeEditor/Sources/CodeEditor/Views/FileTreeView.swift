import SwiftUI
import Foundation
import Core

/// A view that displays a hierarchical file tree with Git status indicators
public struct FileTreeView: View {
    @ObservedObject private var viewModel: CodeEditorViewModel
    @Environment(\.colorScheme) private var colorScheme
    
    public init(viewModel: CodeEditorViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        List {
            ForEach(viewModel.files, id: \.path) { file in
                FileTreeItemView(
                    path: file.path,
                    isDirectory: file.isDirectory,
                    isSelected: viewModel.selectedFile == file.path,
                    gitStatus: getGitStatus(for: file.path)
                )
                .onTapGesture {
                    if !file.isDirectory {
                        viewModel.loadFile(at: file.path)
                    }
                }
            }
        }
        .listStyle(SidebarListStyle())
    }
    
    private func getGitStatus(for file: String) -> String? {
        do {
            let status = try viewModel.gitWrapper.getStatus()
            return status.first { $0.1 == file }?.0
        } catch {
            print("Error getting Git status: \(error)")
            return nil
        }
    }
}

/// A view representing a single item in the file tree
private struct FileTreeItemView: View {
    let path: String
    let isDirectory: Bool
    let isSelected: Bool
    let gitStatus: String?
    
    var body: some View {
        HStack {
            // Icon
            Image(systemName: iconName)
                .foregroundColor(iconColor)
            
            // Name
            Text(path.components(separatedBy: "/").last ?? path)
                .lineLimit(1)
                .truncationMode(.middle)
            
            Spacer()
            
            // Git status indicator
            if let status = gitStatus {
                Text(status)
                    .font(.caption)
                    .foregroundColor(statusColor)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(statusColor.opacity(0.1))
                    .cornerRadius(4)
            }
        }
        .padding(.vertical, 2)
        .background(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
    }
    
    private var iconName: String {
        if isDirectory {
            return "folder.fill"
        }
        
        // Determine icon based on file extension
        let ext = (path as NSString).pathExtension.lowercased()
        switch ext {
        case "swift": return "swift"
        case "md": return "doc.text"
        case "json": return "curlybraces"
        case "yml", "yaml": return "list.bullet"
        case "txt": return "doc.text"
        case "png", "jpg", "jpeg": return "photo"
        default: return "doc"
        }
    }
    
    private var iconColor: Color {
        if isDirectory {
            return .blue
        }
        if let status = gitStatus {
            switch status {
            case "M": return .yellow
            case "A": return .green
            case "D": return .red
            case "??": return .gray
            default: return .primary
            }
        }
        return .primary
    }
    
    private var statusColor: Color {
        switch gitStatus {
        case "M": return .yellow
        case "A": return .green
        case "D": return .red
        case "??": return .gray
        default: return .primary
        }
    }
}

#Preview {
    FileTreeView(viewModel: CodeEditorViewModel(gitWrapper: try! GitWrapper(path: "/")))
        .frame(width: 250)
}
