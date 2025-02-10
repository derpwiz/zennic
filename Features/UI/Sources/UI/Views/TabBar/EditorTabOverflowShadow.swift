import SwiftUI

/// A shadow indicator for tab bar overflow
struct EditorTabOverflowShadow: View {
    @Environment(\.colorScheme) private var colorScheme
    
    /// The side of the tab bar this shadow appears on
    enum Side {
        case leading, trailing
    }
    
    let side: Side
    let width: CGFloat
    
    init(side: Side, width: CGFloat = 5) {
        self.side = side
        self.width = width
    }
    
    var body: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                colorScheme == .dark
                ? .black.opacity(0.4)
                : .black.opacity(0.1),
                .clear
            ]),
            startPoint: side == .leading ? .leading : .trailing,
            endPoint: side == .leading ? .trailing : .leading
        )
        .frame(width: width)
    }
}

struct EditorTabOverflowShadow_Previews: PreviewProvider {
    static var previews: some View {
        HStack(spacing: 0) {
            EditorTabOverflowShadow(side: .leading)
            Color.clear
            EditorTabOverflowShadow(side: .trailing)
        }
        .frame(width: 200, height: EditorTabBarView.height)
        .previewLayout(.sizeThatFits)
    }
}
