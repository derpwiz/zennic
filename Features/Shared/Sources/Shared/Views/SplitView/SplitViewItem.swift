import SwiftUI
import Combine

public class SplitViewItem {
    public var id: AnyHashable
    public var item: NSSplitViewItem
    public var collapsed: Binding<Bool>
    public var cancellables: [AnyCancellable] = []
    public var observers: [NSKeyValueObservation] = []

    public init(child: _VariadicView.Children.Element) {
        self.id = child.id
        self.item = NSSplitViewItem(viewController: NSHostingController(rootView: child))
        self.collapsed = child[SplitViewItemCollapsedViewTraitKey.self]
        self.item.canCollapse = child[SplitViewItemCanCollapseViewTraitKey.self]
        self.item.isCollapsed = self.collapsed.wrappedValue
        self.item.holdingPriority = child[SplitViewHoldingPriorityTraitKey.self]
        // Skip the initial observation via a dispatch to avoid a "updating during view update" error
        DispatchQueue.main.async {
            self.observers = self.createObservers()
        }
    }

    private func createObservers() -> [NSKeyValueObservation] {
        [
            item.observe(\.isCollapsed) { [weak self] item, _ in
                self?.collapsed.wrappedValue = item.isCollapsed
            }
        ]
    }

    /// Updates a SplitViewItem.
    /// This will fetch updated binding values and update them if needed.
    /// - Parameter child: the view corresponding to the SplitViewItem.
    public func update(child: _VariadicView.Children.Element) {
        self.item.canCollapse = child[SplitViewItemCanCollapseViewTraitKey.self]
        DispatchQueue.main.async {
            self.observers = []
            self.item.animator().isCollapsed = child[SplitViewItemCollapsedViewTraitKey.self].wrappedValue
            self.item.holdingPriority = child[SplitViewHoldingPriorityTraitKey.self]
            self.observers = self.createObservers()
        }
    }
}
