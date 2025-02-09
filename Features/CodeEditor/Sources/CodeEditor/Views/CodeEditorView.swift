import SwiftUI
import Foundation
import Core
import Shared
import UI

/// A view that provides code editing functionality with Git integration
public struct CodeEditorView: View {
    @ObservedObject private var viewModel: CodeEditorViewModel
    @ObservedObject private var themeModel: ThemeModel = .shared
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
    
    private var currentTheme: Theme {
        themeModel.selectedTheme ?? (colorScheme == .dark ? .darkDefault : .lightDefault)
    }
    
    public var body: some View {
        HSplitView {
            // File tree sidebar
            FileTreeView(viewModel: viewModel)
                .frame(minWidth: 200, maxWidth: 300)
                .background(EffectView(.sidebar))
            
            // Main editor area
            VStack(spacing: 0) {
                // Tab bar
                HStack {
                    Text(filePath)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .foregroundColor(currentTheme.editor.text)
                    Spacer()
                }
                .padding(.horizontal)
                .frame(height: 40)
                .background(EffectView(.titlebar))
                
                // Editor content
                ThemedTextEditor(
                    text: $viewModel.content,
                    theme: currentTheme,
                    isEditable: isEditable
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // Status bar
                HStack {
                    if let branch = viewModel.currentBranch {
                        Image(systemName: "arrow.triangle.branch")
                            .foregroundColor(currentTheme.editor.text)
                        Text(branch)
                            .foregroundColor(currentTheme.editor.text)
                    }
                    Spacer()
                    if let fileStatus = viewModel.fileStatus {
                        Text(fileStatus)
                            .foregroundColor(currentTheme.editor.lineNumber)
                    }
                }
                .padding(.horizontal)
                .frame(height: 30)
                .background(EffectView(.titlebar))
            }
        }
        .background(currentTheme.editor.background)
        .onAppear {
            themeModel.updateTheme(for: colorScheme)
        }
        .onChange(of: colorScheme) { newValue in
            themeModel.updateTheme(for: newValue)
        }
    }
}

#Preview {
    CodeEditorView(
        viewModel: CodeEditorViewModel(workspacePath: NSTemporaryDirectory()),
        filePath: "example.swift"
    )
}
