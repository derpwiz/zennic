import SwiftUI

/// A view controller that manages a split view and its items
public final class SplitViewController: NSSplitViewController {
    /// The items managed by this split view controller
    var items: [SplitViewItem] = []
    
    /// The axis along which the split view divides its items
    let axis: Axis
    
    /// Reference to the parent view for updating the view controller binding
    private var parentView: SplitViewControllerView
    
    /// Initializes a new split view controller
    /// - Parameters:
    ///   - parent: The parent view that created this controller
    ///   - axis: The axis along which to split items
    init(parent: SplitViewControllerView, axis: Axis = .horizontal) {
        self.axis = axis
        self.parentView = parent
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Configure the split view
        splitView.isVertical = axis != .vertical
        splitView.dividerStyle = .thin
        
        // Update the parent's view controller reference
        DispatchQueue.main.async { [weak self] in
            self?.parentView.viewController = { [weak self] in
                self
            }
        }
    }
    
    override func splitView(
        _ splitView: NSSplitView,
        shouldHideDividerAt dividerIndex: Int
    ) -> Bool {
        false
    }
    
    /// Collapses or expands a split view item
    /// - Parameters:
    ///   - id: The identifier of the item to collapse/expand
    ///   - enabled: Whether to collapse (true) or expand (false)
    func collapse(for id: AnyHashable, enabled: Bool) {
        items.first { $0.id == id }?.item.animator().isCollapsed = enabled
    }
    
    /// Updates the positions of dividers to evenly distribute space
    /// - Parameters:
    ///   - splitView: The split view to update
    ///   - itemCount: The number of items
    private func updateDividerPositions(splitView: NSSplitView, itemCount: Int) {
        let numerator = splitView.isVertical ? splitView.frame.width : splitView.frame.height
        
        for idx in 0..<(itemCount - 1) {
            // Skip if the next view is collapsed
            guard !items[idx + 1].item.isCollapsed else { continue }
            
            // Position needs to be set twice for vertical splits
            let position = CGFloat(idx + 1) * numerator / CGFloat(itemCount)
            splitView.setPosition(position, ofDividerAt: idx)
            splitView.setPosition(position, ofDividerAt: idx)
        }
    }
    
    /// Updates the split view items and their positions
    /// - Returns: Whether any items were added or removed
    func updateItems() -> Bool {
        
        var hasChanged = false
        
        // Update existing items and add new ones
        items = parentView.children.map { child in
            if let existingItem = items.first(where: { $0.id == child.id }) {
                existingItem.update(child: child)
                return existingItem
            } else {
                hasChanged = true
                return SplitViewItem(child: child)
            }
        }
        
        // Update the split view items
        splitViewItems = items.map(\.item)
        
        // Update divider positions if needed
        if hasChanged && splitViewItems.count > 1 {
            updateDividerPositions(splitView: splitView, itemCount: items.count)
        }
        
        return hasChanged
    }
}
