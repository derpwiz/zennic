import SwiftUI

struct SplitView<Content: View>: View {
    var axis: Axis
    var content: Content

    init(axis: Axis, @ViewBuilder content: () -> Content) {
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
    static func horizontal<Content: View>(@ViewBuilder content: () -> Content) -> SplitView<Content> {
        SplitView(axis: .horizontal, content: content)
    }

    static func vertical<Content: View>(@ViewBuilder content: () -> Content) -> SplitView<Content> {
        SplitView(axis: .vertical, content: content)
    }
}
