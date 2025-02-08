import SwiftUI
import CodeEditorInterface

public enum CodeEditorFactoryImpl: CodeEditorFactoryType {
    public static func makeEditor(workspacePath: String) -> AnyView {
        AnyView(CodeEditorContainerView(workspacePath: workspacePath))
    }
}

// Register the implementation
extension CodeEditorFactory {
    public static func initialize() {
        CodeEditorFactory.current = CodeEditorFactoryImpl.self
    }
}
