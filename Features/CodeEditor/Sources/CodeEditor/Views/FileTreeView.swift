import SwiftUI
import Foundation
import Core
import Shared

/// A view that displays a hierarchical file tree
public struct FileTreeView: View {
    @ObservedObject private var viewModel: CodeEditorViewModel
    @ObservedObject private var themeModel: ThemeModel = .shared
    @Environment(\.colorScheme) private var colorScheme
    
    public init(viewModel: CodeEditorViewModel) {
        self.viewModel = viewModel
    }
    
    private var currentTheme: Theme {
        themeModel.selectedTheme ?? (colorScheme == .dark ? .darkDefault : .lightDefault)
    }
    
    public var body: some View {
        List {
            ForEach(viewModel.files, id: \.path) { file in
                FileRow(file: file, viewModel: viewModel, theme: currentTheme)
            }
        }
        .listStyle(.sidebar)
        .background(EffectView(.sidebar))
    }
}

private struct FileRow: View {
    let file: (path: String, isDirectory: Bool)
    @ObservedObject var viewModel: CodeEditorViewModel
    let theme: Theme
    
    private var iconName: String {
        if file.isDirectory {
            return "folder.fill"
        }
        
        let ext = (file.path as NSString).pathExtension.lowercased()
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
        if file.isDirectory {
            return .blue
        }
        return theme.editor.text
    }
    
    var body: some View {
        HStack {
            Image(systemName: iconName)
                .foregroundColor(iconColor)
            Text(file.path.components(separatedBy: "/").last ?? file.path)
                .lineLimit(1)
                .truncationMode(.middle)
                .foregroundColor(theme.editor.text)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if !file.isDirectory {
                viewModel.loadFile(at: file.path)
            }
        }
    }
}

#Preview {
    FileTreeView(viewModel: CodeEditorViewModel(workspacePath: NSTemporaryDirectory()))
        .frame(width: 250)
}
