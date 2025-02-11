import SwiftUI
import Foundation
import Core
import Shared
import CodeEditorInterface

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
    
    private var sidebar: some View {
        FileTreeView(viewModel: viewModel)
            .frame(minWidth: Constants.sidebarWidth.lowerBound,
                   maxWidth: Constants.sidebarWidth.upperBound)
            .background(EffectView(.sidebar))
            .frame(minWidth: 0)
    }
    
    private var editorArea: some View {
        VStack(spacing: 0) {
            tabBar
            editorContent
        }
        .frame(maxWidth: .infinity)
    }
    
    private var tabBar: some View {
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
    }
    
    private var editorContent: some View {
        ThemedTextEditor(
            text: $viewModel.fileContent,
            theme: currentTheme,
            isEditable: isEditable,
            onCursorChange: handleCursorChange,
            onSelectionChange: handleSelectionChange
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func handleCursorChange(line: Int, column: Int, offset: Int) {
        viewModel.cursorLine = line
        viewModel.cursorColumn = column
        viewModel.characterOffset = offset
    }
    
    private func handleSelectionChange(length: Int, lines: Int) {
        viewModel.selectedLength = length
        viewModel.selectedLines = lines
    }
    
    private func setupLifecycle(_ view: some View) -> some View {
        view
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
    
    public var body: some View {
        setupLifecycle(
            HSplitView {
                sidebar
                editorArea
            }
            .background(currentTheme.editor.background)
        )
    }
    
    /// Updates the status bar model with the current state
    private func updateStatusBar() {
        statusBarViewModel.model = viewModel.updateStatusBar()
    }
}

#Preview {
    CodeEditorView(
        viewModel: CodeEditorViewModel(workspacePath: NSTemporaryDirectory()),
        filePath: "example.swift"
    )
}
