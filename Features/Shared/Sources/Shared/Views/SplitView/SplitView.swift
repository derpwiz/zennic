import SwiftUI

struct SplitView<Content: View>: View {
    var axis: Axis
    var content: Content

    init(axis: Axis = .horizontal, @ViewBuilder content: () -> Content) {
        self.axis = axis
        self.content = content()
    }

    @State var viewController: () -> SplitViewController? = { nil }

    var body: some View {
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
    public static func horizontal<V: View>(@ViewBuilder content: () -> V) -> SplitView<V> {
        SplitView(axis: .horizontal, content: content)
    }

    public static func vertical<V: View>(@ViewBuilder content: () -> V) -> SplitView<V> {
        SplitView(axis: .vertical, content: content)
    }
}
