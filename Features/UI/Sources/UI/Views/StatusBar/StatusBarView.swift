import SwiftUI
import Shared

/// A view that displays information and controls in the status bar
public struct StatusBarView: View {
    /// The height of the status bar
    public static let height: CGFloat = 28
    
    /// The current control state
    @Environment(\.controlActiveState) private var controlActive
    
    /// The current color scheme
    @Environment(\.colorScheme) private var colorScheme
    
    /// The split view proxy for resizing the utility area
    private let proxy: Shared.SplitViewProxy
    
    /// Creates a new status bar view
    /// - Parameter proxy: The split view proxy for resizing the utility area
    public init(proxy: Shared.SplitViewProxy = .init(viewController: { nil })) {
        self.proxy = proxy
    }
    
    public var body: some View {
        HStack(alignment: .center, spacing: 10) {
            // Left items
            HStack(spacing: 10) {
                StatusBarIndentSelector()
                StatusBarEncodingSelector()
                StatusBarLineEndSelector()
            }
            
            Spacer()
            
            // Right items
            HStack(spacing: 10) {
                StatusBarFileInfoView()
                StatusBarCursorPositionView()
                StatusBarDivider()
                StatusBarToggleUtilityAreaButton()
            }
        }
        .padding(.horizontal, 10)
        .cursor(.resizeUpDown)
        .frame(height: Self.height)
        .background(.bar)
        .padding(.top, 1)
        .overlay(alignment: .top) {
            Divider()
                .overlay(Color(nsColor: colorScheme == .dark ? .black : .clear))
        }
        .gesture(dragGesture)
        .disabled(controlActive == .inactive)
    }
    
    /// A drag gesture to resize the utility area
    private var dragGesture: some Gesture {
        DragGesture(coordinateSpace: .global)
            .onChanged { value in
                proxy.setPosition(
                    of: 0,
                    position: value.location.y + Self.height / 2
                )
            }
    }
}

/// Extension to add cursor support to views
extension View {
    /// Sets the cursor for this view
    /// - Parameter cursor: The cursor to use
    /// - Returns: A modified view that shows the specified cursor
    func cursor(_ cursor: NSCursor) -> some View {
        onHover { isHovered in
            if isHovered {
                cursor.push()
            } else {
                cursor.pop()
            }
        }
    }
}

#Preview("Status Bar") {
    VStack(spacing: 0) {
        // Light mode
        HStack {
            StatusBarView(proxy: .init(viewController: { nil }))
                .environmentObject(StatusBarViewModel())
                .environmentObject(UtilityAreaViewModel())
                .frame(width: 800)
        }
        .frame(height: 28)
        .background(.bar)
        
        // Dark mode
        HStack {
            StatusBarView(proxy: .init(viewController: { nil }))
                .environmentObject(StatusBarViewModel())
                .environmentObject(UtilityAreaViewModel())
                .frame(width: 800)
        }
        .frame(height: 28)
        .background(.bar)
        .preferredColorScheme(.dark)
    }
}
