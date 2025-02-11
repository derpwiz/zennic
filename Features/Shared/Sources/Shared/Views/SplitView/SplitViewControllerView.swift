import SwiftUI

struct SplitViewControllerView: NSViewControllerRepresentable {
    var axis: Axis
    var children: _VariadicView.Children
    @Binding var viewController: () -> SplitViewController?

    func makeNSViewController(context: Context) -> SplitViewController {
        context.coordinator
    }

    func updateNSViewController(_ controller: SplitViewController, context: Context) {
        updateItems(controller: controller)
    }

    private func updateItems(controller: SplitViewController) {
        var hasChanged = false
        // Reorder viewcontrollers if needed and add new ones.
        controller.items = children.map { child in
            let item: SplitViewItem
            if let foundItem = controller.items.first(where: { $0.id == child.id }) {
                item = foundItem
                item.update(child: child)
            } else {
                hasChanged = true
                item = SplitViewItem(child: child)
            }
            return item
        }

        controller.splitViewItems = controller.items.map(\.item)

        if hasChanged && controller.splitViewItems.count > 1 {
            let splitView = controller.splitView
            let numerator = splitView.isVertical ? splitView.frame.width : splitView.frame.height

            for idx in 0..<controller.items.count-1 {
                // If the next view is collapsed, don't reposition the divider.
                guard !controller.items[idx+1].item.isCollapsed else { continue }

                // This method needs to be run twice to ensure the split works correctly if split vertical.
                // I've absolutely no idea why but it works.
                splitView.setPosition(
                    CGFloat(idx + 1) * numerator/CGFloat(controller.items.count),
                    ofDividerAt: idx
                )
                splitView.setPosition(
                    CGFloat(idx + 1) * numerator/CGFloat(controller.items.count),
                    ofDividerAt: idx
                )
            }
        }
    }

    func makeCoordinator() -> SplitViewController {
        SplitViewController(parent: self, axis: axis)
    }
}
