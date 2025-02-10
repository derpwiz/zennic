import SwiftUI

/// The main tab bar view for the editor
public struct EditorTabBarView: View {
    /// The height of tab bar
    static let height: CGFloat = 28.0
    
    @EnvironmentObject private var editorManager: EditorManager
    
    public init() {}
    
    public var body: some View {
        HStack(alignment: .center, spacing: 0) {
            // Leading accessories (placeholder for now)
            leadingAccessories
            
            // Tab list with horizontal scrolling
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: -1) { // Negative spacing for overlapping dividers
                    ForEach(editorManager.tabs) { tab in
                        EditorTabItemView(tab: tab)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            
            // Trailing accessories (placeholder for now)
            trailingAccessories
        }
        .frame(height: Self.height)
        .padding(.leading, -1) // Compensate for first divider
    }
    
    private var leadingAccessories: some View {
        HStack(spacing: 8) {
            // Placeholder for leading accessories
            EmptyView()
        }
        .padding(.horizontal, 8)
    }
    
    private var trailingAccessories: some View {
        HStack(spacing: 8) {
            // Placeholder for trailing accessories
            EmptyView()
        }
        .padding(.horizontal, 8)
    }
}

// MARK: - Preview
struct EditorTabBarView_Previews: PreviewProvider {
    static var previews: some View {
        EditorTabBarView()
            .environmentObject(EditorManager())
    }
}
