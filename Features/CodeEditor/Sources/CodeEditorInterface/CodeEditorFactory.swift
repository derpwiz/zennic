import SwiftUI

public protocol CodeEditorFactoryType {
    static func makeEditor(workspacePath: String) -> AnyView
}

public enum CodeEditorFactory: CodeEditorFactoryType {
    public static func makeEditor(workspacePath: String) -> AnyView {
        // This will be implemented by the CodeEditor module
        AnyView(EmptyView())
    }
}
