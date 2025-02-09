import SwiftUI

/// A view that arranges its children in a split view layout
public struct SplitView<Content: View>: View {
    /// The axis along which to split the views
    private let axis: Axis
    
    /// The content to display in the split view
    private let content: Content
    
    /// Reference to the split view controller
    @State private var viewController: () -> SplitViewController? = { nil }
    
    /// Creates a new split view
    /// - Parameters:
    ///   - axis: The axis along which to split the views (horizontal or vertical)
    ///   - content: A view builder that creates the content views
    public init(axis: Axis, @ViewBuilder content: () -> Content) {
        self.axis = axis
        self.content = content()
    }
    
    public var body: some View {
        VStack {
            content.variadic { children in
                SplitViewControllerView(
                    axis: axis,
                    children: children,
                    viewController: $viewController
                )
            }
        }
        ._trait(SplitViewControllerLayoutValueKey.self, viewController)
        .accessibilityElement(children: .contain)
    }
}

/// Extension to provide a more SwiftUI-like API for SplitView
public extension SplitView {
    /// Creates a horizontal split view
    /// - Parameter content: A view builder that creates the content views
    /// - Returns: A horizontal split view
    static func horizontal<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> SplitView<Content> {
        SplitView(axis: .horizontal, content: content)
    }
    
    /// Creates a vertical split view
    /// - Parameter content: A view builder that creates the content views
    /// - Returns: A vertical split view
    static func vertical<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> SplitView<Content> {
        SplitView(axis: .vertical, content: content)
    }
}

#Preview {
    SplitView.horizontal {
        Color.red
            .frame(minWidth: 200, maxWidth: 300)
            .collapsible()
        
        Color.blue
            .frame(maxWidth: .infinity)
        
        Color.green
            .frame(width: 200)
            .collapsible()
    }
    .frame(width: 800, height: 400)
}
