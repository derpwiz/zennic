import SwiftUI
import Foundation
import Core
import Shared
import UI

// MARK: - Constants
private enum Constants {
    static let sidebarWidth: ClosedRange<CGFloat> = 200...300
    static let tabBarHeight: CGFloat = 40
    static let statusBarHeight: CGFloat = 30
}

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
        SplitView.horizontal {
            // File tree sidebar
            FileTreeView(viewModel: viewModel)
                .frame(minWidth: Constants.sidebarWidth.lowerBound,
                       maxWidth: Constants.sidebarWidth.upperBound)
                .background(EffectView(.sidebar))
                .collapsible()
            
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
                .frame(height: Constants.tabBarHeight)
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
                .frame(height: Constants.statusBarHeight)
                .background(EffectView(.titlebar))
            }
            .frame(maxWidth: .infinity)
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
