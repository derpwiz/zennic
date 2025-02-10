import SwiftUI

public struct SplitViewControllerPreferenceKey: PreferenceKey {
    public static var defaultValue: SplitViewController? = nil
    public static func reduce(value: inout SplitViewController?, nextValue: () -> SplitViewController?) {
        value = nextValue()
    }
}

/// A view that provides access to the parent split view controller
public struct SplitViewReader<Content: View>: View {
    /// The content to display
    @ViewBuilder var content: (SplitViewProxy) -> Content
    
    @State private var viewController: SplitViewController?
    
    private var proxy: SplitViewProxy {
        .init(viewController: { viewController })
    }
    
    /// Creates a new split view reader
    /// - Parameter content: A closure that takes a split view proxy and returns a view
    public init(@ViewBuilder content: @escaping (SplitViewProxy) -> Content) {
        self.content = content
    }
    
    public var body: some View {
        content(proxy)
            .onPreferenceChange(SplitViewControllerPreferenceKey.self) { controller in
                viewController = controller
            }
    }
}

/// A proxy for interacting with the split view controller
public struct SplitViewProxy {
    private var viewController: () -> SplitViewController?
    
    public init(viewController: @escaping () -> SplitViewController?) {
        self.viewController = viewController
    }
    
    /// Set the position of a divider in a splitview
    /// - Parameters:
    ///   - index: index of the divider. The leftmost/top divider has index 0
    ///   - position: position to place the divider. This is a position inside the views width/height
    public func setPosition(of index: Int, position: CGFloat) {
        viewController()?.splitView.setPosition(position, ofDividerAt: index)
    }
    
    /// Collapse a view of the splitview
    /// - Parameters:
    ///   - id: ID of the view
    ///   - enabled: true for collapse
    public func collapseView(with id: AnyHashable, _ enabled: Bool) {
        viewController()?.collapse(for: id, enabled: enabled)
    }
    
    /// Collapse a view of the splitview (deprecated)
    /// - Parameters:
    ///   - id: ID of the view
    ///   - enabled: true for collapse
    @available(*, deprecated, message: "Use collapseView(with:_:) instead")
    public func collapse(for id: AnyHashable, enabled: Bool) {
        collapseView(with: id, enabled)
    }
}
