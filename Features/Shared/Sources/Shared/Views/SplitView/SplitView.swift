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
        content.modifier(SplitViewModifier(
            axis: axis,
            viewController: $viewController
        ))
        ._trait(SplitViewControllerLayoutValueKey.self, viewController)
        .accessibilityElement(children: .contain)
    }
}

/// Extension to provide a more SwiftUI-like API for SplitView
public extension SplitView {
    /// Creates a horizontal split view
    /// - Parameter content: A view builder that creates the content views
    /// - Returns: A horizontal split view
    static func horizontal(
        @ViewBuilder content: () -> Content
    ) -> Self {
        SplitView(axis: .horizontal, content: content)
    }
    
    /// Creates a vertical split view
    /// - Parameter content: A view builder that creates the content views
    /// - Returns: A vertical split view
    static func vertical(
        @ViewBuilder content: () -> Content
    ) -> Self {
        SplitView(axis: .vertical, content: content)
    }
}

private struct SplitViewModifier: ViewModifier {
    let axis: Axis
    @Binding var viewController: () -> SplitViewController?
    
    func body(content: Content) -> some View {
        Group {
            if let children = (content as? _VariadicView_Children)?.children {
                SplitViewControllerView(
                    axis: axis,
                    children: children,
                    viewController: $viewController
                )
            } else {
                content
            }
        }
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
