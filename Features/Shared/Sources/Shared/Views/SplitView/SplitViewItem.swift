import SwiftUI
import AppKit
import Combine

public final class SplitViewItem: SplitViewItemProtocol {
    public let id: AnyHashable
    internal let item: NSSplitViewItem
    
    internal var collapsed: Binding<Bool>
    internal var observers: [NSKeyValueObservation] = []
    
    public var isCollapsed: Bool {
        item.isCollapsed
    }
    
    public var canCollapse: Bool {
        item.canCollapse
    }
    
    public var holdingPriority: Float? {
        item.holdingPriority
    }
    
    internal init(child: _VariadicView.Children.Element) {
        self.id = child.id
        self.item = NSSplitViewItem(viewController: NSHostingController(rootView: AnyView(child)))
        self.collapsed = child[SplitViewItemCollapsedViewTraitKey.self]
        self.item.canCollapse = child[SplitViewItemCanCollapseViewTraitKey.self]
        self.item.isCollapsed = self.collapsed.wrappedValue
        self.item.holdingPriority = child[SplitViewHoldingPriorityTraitKey.self]
        
        // Skip the initial observation via a dispatch to avoid a "updating during view update" error
        DispatchQueue.main.async {
            self.observers = self.createObservers()
        }
    }
    
    internal func createObservers() -> [NSKeyValueObservation] {
        [
            item.observe(\.isCollapsed) { [weak self] item, _ in
                self?.collapsed.wrappedValue = item.isCollapsed
            }
        ]
    }
    
    internal func update(child: _VariadicView.Children.Element) {
        (item.viewController as? NSHostingController<AnyView>)?.rootView = AnyView(child)
        self.item.canCollapse = child[SplitViewItemCanCollapseViewTraitKey.self]
        DispatchQueue.main.async {
            self.observers = []
            self.item.animator().isCollapsed = child[SplitViewItemCollapsedViewTraitKey.self].wrappedValue
            self.item.holdingPriority = child[SplitViewHoldingPriorityTraitKey.self]
            self.observers = self.createObservers()
        }
    }
}
