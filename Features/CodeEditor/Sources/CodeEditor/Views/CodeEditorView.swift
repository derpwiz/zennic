import SwiftUI
import Foundation
import Core
import Shared

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
    
    /// The status bar view model
    @StateObject private var statusBarViewModel = StatusBarViewModel()
    
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
        UtilityAreaSplitView {
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
                        isEditable: isEditable,
                        onCursorChange: { line, column, offset in
                            viewModel.cursorLine = line
                            viewModel.cursorColumn = column
                            viewModel.characterOffset = offset
                        },
                        onSelectionChange: { length, lines in
                            viewModel.selectedLength = length
                            viewModel.selectedLines = lines
                        }
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .frame(maxWidth: .infinity)
            }
            .environmentObject(statusBarViewModel)
        }
        .background(currentTheme.editor.background)
        .onAppear {
            themeModel.updateTheme(for: colorScheme)
            updateStatusBar()
        }
        .onChange(of: colorScheme) { newValue in
            themeModel.updateTheme(for: newValue)
        }
        .onChange(of: viewModel.cursorLine) { _ in updateStatusBar() }
        .onChange(of: viewModel.cursorColumn) { _ in updateStatusBar() }
        .onChange(of: viewModel.characterOffset) { _ in updateStatusBar() }
        .onChange(of: viewModel.selectedLength) { _ in updateStatusBar() }
        .onChange(of: viewModel.selectedLines) { _ in updateStatusBar() }
        .onChange(of: viewModel.fileSize) { _ in updateStatusBar() }
    }
    
    /// Updates the status bar model with the current state
    private func updateStatusBar() {
        statusBarViewModel.model = StatusBarModel(
            fileSize: viewModel.fileSize,
            line: viewModel.cursorLine,
            column: viewModel.cursorColumn,
            characterOffset: viewModel.characterOffset,
            selectedLength: viewModel.selectedLength,
            selectedLines: viewModel.selectedLines
        )
    }
}

#Preview {
    CodeEditorView(
        viewModel: CodeEditorViewModel(workspacePath: NSTemporaryDirectory()),
        filePath: "example.swift"
    )
}
