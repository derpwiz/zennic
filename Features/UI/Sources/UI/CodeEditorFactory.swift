import SwiftUI
import CodeEditor

public enum CodeEditorFactory {
    public static func makeEditor(workspacePath: String) -> AnyView {
        AnyView(CodeEditorContainerView(workspacePath: workspacePath))
    }
}
