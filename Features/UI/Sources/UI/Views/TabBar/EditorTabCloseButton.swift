import SwiftUI

/// Close button for editor tabs
struct EditorTabCloseButton: View {
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var editorManager: EditorManager
    
    let tab: EditorTab
    
    @State private var isHovering: Bool = false
    @State private var isPressed: Bool = false
    
    private var backgroundColor: Color {
        if isPressed {
            return .red.opacity(0.8)
        } else if isHovering {
            return colorScheme == .dark
                ? .white.opacity(0.2)
                : .black.opacity(0.1)
        }
        return .clear
    }
    
    var body: some View {
        Button {
            editorManager.closeTab(tab)
        } label: {
            Image(systemName: "xmark")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(
                    isHovering
                    ? (colorScheme == .dark ? .white : .black)
                    : .secondary
                )
                .frame(width: 16, height: 16)
                .contentShape(Rectangle())
                .background(
                    Circle()
                        .fill(backgroundColor)
                )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovering = hovering
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

struct EditorTabCloseButton_Previews: PreviewProvider {
    static var previews: some View {
        let manager = EditorManager()
        let tab = EditorTab(
            id: .file("test.swift"),
            name: "test.swift",
            path: "test.swift"
        )
        
        return EditorTabCloseButton(tab: tab)
            .environmentObject(manager)
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
