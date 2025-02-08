import SwiftUI

public protocol CodeEditorFactoryType {
    static func makeEditor(workspacePath: String) -> AnyView
}

public enum CodeEditorFactory {
    public static var current: CodeEditorFactoryType.Type = DefaultFactory.self
    
    public static func makeEditor(workspacePath: String) -> AnyView {
        current.makeEditor(workspacePath: workspacePath)
    }
    
    public static func initialize() {
        // This will be implemented by the CodeEditor module
    }
    
    private enum DefaultFactory: CodeEditorFactoryType {
        public static func makeEditor(workspacePath: String) -> AnyView {
            AnyView(EmptyView())
        }
    }
}
