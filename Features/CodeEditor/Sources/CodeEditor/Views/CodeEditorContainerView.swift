import SwiftUI
import Core
import CodeEditorInterface
import Shared

/// A container view that manages the code editor and its state
public struct CodeEditorContainerView: View {
    @StateObject private var viewModel: CodeEditorViewModel
    @ObservedObject private var themeModel: ThemeModel = .shared
    @Environment(\.colorScheme) private var colorScheme
    
    public let workspacePath: String
    
    public init(workspacePath: String) {
        self.workspacePath = workspacePath
        self._viewModel = StateObject(wrappedValue: CodeEditorViewModel(workspacePath: workspacePath))
    }
    
    private var currentTheme: Theme {
        themeModel.selectedTheme ?? (colorScheme == .dark ? .darkDefault : .lightDefault)
    }
    
    public var body: some View {
        Group {
            if let error = viewModel.error {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 48))
                        .foregroundColor(.red)
                    Text(error)
                        .multilineTextAlignment(.center)
                        .foregroundColor(currentTheme.editor.text)
                    Button(action: {
                        viewModel.initializeGit()
                    }) {
                        Label("Initialize Git Repository", systemImage: "plus.circle")
                            .foregroundColor(currentTheme.editor.text)
                    }
                    .buttonStyle(.borderless)
                }
                .padding()
                .background(EffectView(.contentBackground))
            } else {
                CodeEditorView(viewModel: viewModel, filePath: viewModel.selectedFile ?? "No file selected")
                    .onAppear {
                        // Scan the workspace directory when the view appears
                        viewModel.scanDirectory(path: workspacePath)
                    }
            }
        }
        .onAppear {
            themeModel.updateTheme(for: colorScheme)
        }
        .onChange(of: colorScheme) { newValue in
            themeModel.updateTheme(for: newValue)
        }
    }
}

#Preview {
    CodeEditorContainerView(workspacePath: "/")
        .frame(width: 800, height: 600)
}
