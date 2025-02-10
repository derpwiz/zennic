import SwiftUI

/// A vertical divider between tab bar items
struct EditorTabDivider: View {
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Rectangle()
            .fill(
                colorScheme == .dark
                ? Color.black.opacity(0.4)
                : Color.black.opacity(0.1)
            )
            .frame(width: 1)
            .frame(maxHeight: .infinity)
    }
}

struct EditorTabDivider_Previews: PreviewProvider {
    static var previews: some View {
        EditorTabDivider()
            .frame(height: EditorTabBarView.height)
            .previewLayout(.sizeThatFits)
    }
}
