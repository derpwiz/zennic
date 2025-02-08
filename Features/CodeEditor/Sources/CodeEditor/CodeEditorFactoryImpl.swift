import SwiftUI
import CodeEditorInterface

extension CodeEditorFactory {
    public static func makeEditor(workspacePath: String) -> AnyView {
        AnyView(CodeEditorContainerView(workspacePath: workspacePath))
    }
}
