import SwiftUI

/// A single tab item in the editor tab bar
struct EditorTabItemView: View {
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var editorManager: EditorManager
    
    let tab: EditorTab
    
    private var isSelected: Bool {
        editorManager.selectedTab?.id == tab.id
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
            }
            .padding(.horizontal, 20)
            .frame(height: EditorTabBarView.height)
            .contentShape(Rectangle())
            .background(
                Color(nsColor: isSelected ? .controlAccentColor : .clear)
                    .opacity(colorScheme == .dark ? 0.3 : 0.1)
            )
            .onTapGesture {
                editorManager.selectTab(tab)
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
