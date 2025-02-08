import SwiftUI
import CodeEditorInterface

public enum CodeEditorFactory: CodeEditorFactoryType {
    public static func makeEditor(workspacePath: String) -> AnyView {
        CodeEditorInterface.CodeEditorFactory.makeEditor(workspacePath: workspacePath)
    }
}
