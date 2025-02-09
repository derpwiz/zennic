import SwiftUI
import Combine

/// A class that manages a single item in a split view
final class SplitViewItem: ObservableObject {
    /// The unique identifier for this item
    let id: AnyHashable
    
    /// The underlying NSSplitViewItem
    let item: NSSplitViewItem
    
    /// Binding to the collapsed state
    private let collapsed: Binding<Bool>
    
    /// Cancellables for managing subscriptions
    private var cancellables: [AnyCancellable] = []
    
    /// Key-value observers for monitoring state changes
    private var observers: [NSKeyValueObservation] = []
    
    /// Initializes a new split view item
    /// - Parameter child: The view to be contained in this split view item
    init(child: _VariadicView.Children.Element) {
        self.id = child.id
        self.item = NSSplitViewItem(viewController: NSHostingController(rootView: child))
        self.collapsed = child[SplitViewItemCollapsedViewTraitKey.self]
        self.item.canCollapse = child[SplitViewItemCanCollapseViewTraitKey.self]
        self.item.isCollapsed = self.collapsed.wrappedValue
        self.item.holdingPriority = child[SplitViewHoldingPriorityTraitKey.self]
        
        // Skip the initial observation via a dispatch to avoid a "updating during view update" error
        DispatchQueue.main.async { [weak self] in
            self?.observers = self?.createObservers() ?? []
        }
    }
    
    /// Creates observers for monitoring state changes
    /// - Returns: Array of key-value observers
    private func createObservers() -> [NSKeyValueObservation] {
        [
            item.observe(\.isCollapsed) { [weak self] item, _ in
                self?.collapsed.wrappedValue = item.isCollapsed
            }
        ]
    }
    
    /// Updates the split view item with new values from the child view
    /// - Parameter child: The updated child view
    func update(child: _VariadicView.Children.Element) {
        self.item.canCollapse = child[SplitViewItemCanCollapseViewTraitKey.self]
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Remove existing observers before updating
            self.observers = []
            
            // Update values with animation
            self.item.animator().isCollapsed = child[SplitViewItemCollapsedViewTraitKey.self].wrappedValue
            self.item.holdingPriority = child[SplitViewHoldingPriorityTraitKey.self]
            
            // Recreate observers
            self.observers = self.createObservers()
        }
    }
}
