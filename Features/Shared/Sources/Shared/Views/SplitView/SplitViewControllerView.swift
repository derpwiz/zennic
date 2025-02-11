import SwiftUI

public struct SplitViewControllerView: NSViewControllerRepresentable {
    var axis: Axis
    var children: _VariadicView.Children
    @Binding var viewController: () -> SplitViewControllerProtocol?

    public func makeNSViewController(context: Context) -> NSViewController {
        if #available(macOS 14.0, *) {
            return SplitViewController(parent: self, axis: axis)
        } else {
            return SplitViewControllerWrapper(axis: axis)
        }
    }

    public func updateNSViewController(_ controller: NSViewController, context: Context) {
        if let splitController = controller as? SplitViewControllerProtocol {
            var hasChanged = false
            // Reorder viewcontrollers if needed and add new ones.
            splitController.items = children.map { child in
                let item: SplitViewItem
                if let foundItem = splitController.items.first(where: { $0.id == child.id }) {
                    item = foundItem
                    item.update(child: child)
                } else {
                    hasChanged = true
                    item = SplitViewItem(child: child)
                }
                return item
            }
        }
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    public class Coordinator {}
}
