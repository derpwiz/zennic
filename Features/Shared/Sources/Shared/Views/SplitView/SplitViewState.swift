import SwiftUI

@MainActor public final class SplitViewState: ObservableObject {
    @Published public private(set) var items: [SplitViewItemProtocol] {
        get { _items }
        set { _items = newValue as! [SplitViewItem] } // swiftlint:disable:this force_cast
    }
    private var _items: [SplitViewItem] = []
    
    public init() {}
    
    internal func updateItems(children: _VariadicView.Children, completion: @escaping ([SplitViewItem]) -> Void) {
        let newItems = children.map { child -> SplitViewItem in
            if let existingItem = items.first(where: { $0.id == child.id }) {
                existingItem.update(child: child)
                return existingItem
            }
            return SplitViewItem(child: child)
        }
        items = newItems
        completion(newItems)
    }
    
    internal func updateLayout(splitView: NSSplitView, items: [SplitViewItem]) {
        guard items.count > 1 else { return }
        
        let numerator = splitView.isVertical ? splitView.frame.width : splitView.frame.height
        
        for idx in 0..<items.count-1 {
            // If the next view is collapsed, don't reposition the divider.
            guard !items[idx+1].item.isCollapsed else { continue }
            
            // This method needs to be run twice to ensure the split works correctly if split vertical.
            // I've absolutely no idea why but it works.
            splitView.setPosition(
                CGFloat(idx + 1) * numerator/CGFloat(items.count),
                ofDividerAt: idx
            )
            splitView.setPosition(
                CGFloat(idx + 1) * numerator/CGFloat(items.count),
                ofDividerAt: idx
            )
        }
    }
}
