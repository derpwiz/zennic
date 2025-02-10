import SwiftUI

/// The main tab bar view for the editor
public struct EditorTabBarView: View {
    /// The height of tab bar
    static let height: CGFloat = 28.0
    
    @EnvironmentObject private var editorManager: EditorManager
    
    public init() {}
    
    @State private var scrollOffset: CGFloat = 0
    @State private var scrollTrailingOffset: CGFloat? = 0
    
    public var body: some View {
        HStack(alignment: .center, spacing: 0) {
            // Leading accessories (placeholder for now)
            leadingAccessories
            
            // Tab list with horizontal scrolling
            GeometryReader { geometry in
                ScrollView(.horizontal, showsIndicators: false) {
                    ScrollViewReader { scrollReader in
                        HStack(spacing: -1) { // Negative spacing for overlapping dividers
                            ForEach(editorManager.tabs) { tab in
                                EditorTabItemView(tab: tab)
                            }
                        }
                        .onChange(of: editorManager.selectedTab) { newValue in
                            withAnimation {
                                scrollReader.scrollTo(newValue?.id)
                            }
                        }
                    }
                }
                .overlay(alignment: .leading) {
                    EditorTabOverflowShadow(side: .leading)
                        .opacity(scrollOffset > 0 ? 1 : 0)
                }
                .overlay(alignment: .trailing) {
                    EditorTabOverflowShadow(side: .trailing)
                        .opacity((scrollTrailingOffset ?? 0) > 0 ? 1 : 0)
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
