import SwiftUI

/// A single tab item in the editor tab bar
struct EditorTabItemView: View {
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var editorManager: EditorManager
    
    let tab: EditorTab
    
    private var isSelected: Bool {
        editorManager.selectedTab?.id == tab.id
    }
    
    @State private var isHovering: Bool = false
    
    private var backgroundColor: Color {
        if isSelected {
            return Color(nsColor: .controlAccentColor)
                .opacity(colorScheme == .dark ? 0.3 : 0.1)
        } else if isHovering {
            return colorScheme == .dark
                ? .white.opacity(0.05)
                : .black.opacity(0.03)
        }
        return .clear
    }
    
    var body: some View {
        HStack(spacing: 0) {
            EditorTabDivider()
            
            // Tab content
            HStack(alignment: .center, spacing: 3) {
                Image(nsImage: tab.icon)
                    .resizable()
                    .frame(width: 16, height: 16)
                    .foregroundColor(tab.iconColor)
                
                Text(tab.name)
                    .font(.system(size: 11))
                    .lineLimit(1)
                
                if isHovering || isSelected {
                    EditorTabCloseButton(tab: tab)
                        .transition(.opacity)
                }
            }
            .padding(.horizontal, isHovering || isSelected ? 12 : 20)
            .frame(height: EditorTabBarView.height)
            .contentShape(Rectangle())
            .background(backgroundColor)
            .animation(.easeInOut(duration: 0.15), value: isHovering)
            .animation(.easeInOut(duration: 0.15), value: isSelected)
            .onTapGesture {
                editorManager.selectTab(tab)
            }
            .onHover { hovering in
                isHovering = hovering
            }
            
            EditorTabDivider()
        }
    }
}

struct EditorTabItemView_Previews: PreviewProvider {
    static var previews: some View {
        let manager = EditorManager()
        let tab = EditorTab(
            id: .file("test.swift"),
            name: "test.swift",
            path: "test.swift"
        )
        manager.openTab(tab)
        
        return EditorTabItemView(tab: tab)
            .environmentObject(manager)
            .previewLayout(.sizeThatFits)
    }
}
