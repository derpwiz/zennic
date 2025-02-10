import SwiftUI
import AppKit

internal struct SplitViewControllerView: NSViewControllerRepresentable {
    internal var axis: Axis
    internal var children: _VariadicView.Children
    @Binding internal var viewController: SplitViewController?
    private let state = SplitViewState()
    
    internal init(axis: Axis, children: _VariadicView.Children, viewController: Binding<SplitViewController?>) {
        self.axis = axis
        self.children = children
        self._viewController = viewController
    }
    
    internal func makeNSViewController(context: Context) -> SplitViewController {
        context.coordinator
    }
    
    internal func updateNSViewController(_ controller: SplitViewController, context: Context) {
        state.updateItems(children: children) { (newItems: [SplitViewItem]) in
            controller.items = newItems
            controller.splitViewItems = newItems.map { $0.item }
            
            if controller.splitViewItems.count > 1 {
                state.updateLayout(splitView: controller.splitView, items: newItems)
            }
        }
    }
    
    internal func makeCoordinator() -> SplitViewController {
        let controller = SplitViewController(parent: self, axis: axis)
        viewController = controller
        return controller
    }
}
