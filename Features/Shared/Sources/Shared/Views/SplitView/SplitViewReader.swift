import SwiftUI

public struct SplitViewReader<Content: View>: View {
    @ViewBuilder public var content: (SplitViewProxy) -> Content
    @State private var viewController: () -> SplitViewController? = { nil }

    public init(@ViewBuilder content: @escaping (SplitViewProxy) -> Content) {
        self.content = content
    }

    private var proxy: SplitViewProxy {
        .init(viewController: viewController)
    }

    public var body: some View {
        content(proxy)
            .variadic { children in
                buildChildren(children)
            }
    }
    
    private struct TaskView: View {
        let child: _VariadicView.Children.Element
        let taskId: () -> SplitViewController?
        @Binding var viewController: () -> SplitViewController?
        
        public var body: some View {
            child
                .task(id: taskId()) {
                    viewController = taskId
                }
                ._trait(SplitViewControllerLayoutValueKey.self, taskId)
        }
    }
    
    @ViewBuilder
    private func buildChildren(_ children: _VariadicView.Children) -> some View {
        let childViews = children.enumerated().map { index, child -> (id: Int, view: TaskView) in
            let taskId: () -> SplitViewController? = child[SplitViewControllerLayoutValueKey.self]
            return (
                id: index,
                view: TaskView(
                    child: child,
                    taskId: taskId,
                    viewController: $viewController
                )
            )
        }
        
        if childViews.isEmpty {
            EmptyView()
        } else {
            ForEach(childViews, id: \.id) { pair in
                pair.view
            }
        }
    }
}

public struct SplitViewProxy {
    private var viewController: () -> SplitViewController?

    public init(viewController: @escaping () -> SplitViewController?) {
        self.viewController = viewController
    }

    /// Set the position of a divider in a splitview.
    /// - Parameters:
    ///   - index: index of the divider. The mostleft / top divider has index 0.
    ///   - position: position to place the divider. This is a position inside the views width / height.
    ///   For example, if the splitview has a width of 500, setting the position to 250
    ///    will put the divider in the middle of the splitview.
    public func setPosition(of index: Int, position: CGFloat) {
        viewController()?.splitView.setPosition(position, ofDividerAt: index)
    }

    /// Collapse a view of the splitview.
    /// - Parameters:
    ///   - id: ID of the view
    ///   - enabled: true for collapse.
    public func collapseView(with id: AnyHashable, _ enabled: Bool) {
        viewController()?.collapse(for: id, enabled: enabled)
    }
}
