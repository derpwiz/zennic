import SwiftUI
import Core
import CodeEditorInterface

/// A container view that manages the code editor and its state
public struct CodeEditorContainerView: View {
    @StateObject private var viewModel: CodeEditorViewModel
    public let workspacePath: String
    
    public init(workspacePath: String) {
        self.workspacePath = workspacePath
        self._viewModel = StateObject(wrappedValue: CodeEditorViewModel(workspacePath: workspacePath))
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
                        .foregroundColor(.secondary)
                }
                .padding()
            } else {
                CodeEditorView(viewModel: viewModel, filePath: viewModel.selectedFile ?? "No file selected")
                    .onAppear {
                        // Scan the workspace directory when the view appears
                        viewModel.scanDirectory(path: workspacePath)
                    }
            }
        }
    }
}

#Preview {
    CodeEditorContainerView(workspacePath: "/")
        .frame(width: 800, height: 600)
}
