import SwiftUI
import Shared

public struct ThemedTextEditor: View {
    @Binding private var text: String
    private let theme: Theme
    private let isEditable: Bool
    private let onCursorChange: (Int, Int, Int) -> Void
    private let onSelectionChange: (Int, Int) -> Void
    
    public init(
        text: Binding<String>,
        theme: Theme,
        isEditable: Bool,
        onCursorChange: @escaping (Int, Int, Int) -> Void,
        onSelectionChange: @escaping (Int, Int) -> Void
    ) {
        self._text = text
        self.theme = theme
        self.isEditable = isEditable
        self.onCursorChange = onCursorChange
        self.onSelectionChange = onSelectionChange
    }
    
    public var body: some View {
        TextEditor(text: $text)
            .font(.system(.body, design: .monospaced))
            .foregroundColor(theme.editor.text)
            .disabled(!isEditable)
    }
}
