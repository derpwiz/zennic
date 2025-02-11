import SwiftUI

public struct SplitView<Content: View>: View {
    public var axis: Axis
    public var content: Content

    public init(axis: Axis = .horizontal, @ViewBuilder content: () -> Content) {
        self.axis = axis
        self.content = content()
    }

    @State var viewController: () -> SplitViewController? = { nil }

    public var body: some View {
        VStack {
            content.variadic { children in
                SplitViewControllerView(axis: axis, children: children, viewController: $viewController)
            }
        }
        ._trait(SplitViewControllerLayoutValueKey.self, viewController)
        .accessibilityElement(children: .contain)
    }
}

extension SplitView {
    /// Creates a horizontal split view
    public static func horizontal(@ViewBuilder content: () -> Content) -> SplitView<Content> {
        SplitView(axis: .horizontal, content: content)
    }

    /// Creates a vertical split view
    public static func vertical(@ViewBuilder content: () -> Content) -> SplitView<Content> {
        SplitView(axis: .vertical, content: content)
    }
}
