import SwiftUI
import Foundation

/// A view that provides code editing functionality with Git integration
public struct CodeEditorView: View {
    @ObservedObject private var viewModel: CodeEditorViewModel
    @Environment(\.colorScheme) private var colorScheme
    
    private let isEditable: Bool
    private let filePath: String
    
    public init(
        viewModel: CodeEditorViewModel,
        filePath: String,
        isEditable: Bool = true
    ) {
        self.viewModel = viewModel
        self.filePath = filePath
        self.isEditable = isEditable
    }
    
    public var body: some View {
        HSplitView {
            // File tree sidebar
            FileTreeView(viewModel: viewModel)
                .frame(minWidth: 200, maxWidth: 300)
            
            // Main editor area
            VStack(spacing: 0) {
                // Tab bar
                HStack {
                    Text(filePath)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Spacer()
                }
                .padding(.horizontal)
                .frame(height: 40)
                .background(colorScheme == .dark ? Color.black.opacity(0.2) : Color.white)
                
                // Editor content
                ScrollView([.horizontal, .vertical]) {
                    TextEditor(text: $viewModel.content)
                        .font(.system(.body, design: .monospaced))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .disabled(!isEditable)
                }
                
                // Status bar
                HStack {
                    if let branch = viewModel.currentBranch {
                        Image(systemName: "arrow.triangle.branch")
                        Text(branch)
                    }
                    Spacer()
                    if let fileStatus = viewModel.fileStatus {
                        Text(fileStatus)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)
                .frame(height: 30)
                .background(colorScheme == .dark ? Color.black.opacity(0.2) : Color.white)
            }
        }
    }
}

#Preview {
    CodeEditorView(
        viewModel: CodeEditorViewModel(gitWrapper: try! GitWrapper(path: "/")),
        filePath: "example.swift"
    )
}
