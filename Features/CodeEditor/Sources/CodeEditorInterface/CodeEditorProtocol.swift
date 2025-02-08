import SwiftUI
import Core

/// Protocol defining the interface for code editor views
public protocol CodeEditorViewProtocol: View {
    var workspacePath: String { get }
}

/// A type-erased wrapper for code editor views
public struct AnyCodeEditorView: View {
    private let content: AnyView
    public let workspacePath: String
    
    public init<V: CodeEditorViewProtocol>(_ view: V) {
        self.content = AnyView(view)
        self.workspacePath = view.workspacePath
    }
    
    public var body: some View {
        content
    }
}

/// Factory for creating code editor views
public enum CodeEditorFactory {
    public static func makeEditor(workspacePath: String) -> AnyCodeEditorView {
        // This will be implemented by the CodeEditor module
        AnyCodeEditorView(
            CodeEditorContainerView(workspacePath: workspacePath)
        )
    }
}
