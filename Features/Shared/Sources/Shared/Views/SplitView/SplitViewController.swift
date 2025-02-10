import SwiftUI
import AppKit

internal final class SplitViewController: NSSplitViewController, SplitViewControllerType {
    internal var items: [SplitViewItem] = []
    internal var axis: Axis
    internal var parentView: SplitViewControllerView
    
    internal init(parent: SplitViewControllerView, axis: Axis = .horizontal) {
        self.axis = axis
        self.parentView = parent
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        splitView.isVertical = axis != .vertical
        splitView.dividerStyle = .thin
        DispatchQueue.main.async { [weak self] in
            self?.parentView.viewController = { [weak self] in
                self
            }()
        }
    }
    
    override func splitView(_ splitView: NSSplitView, shouldHideDividerAt dividerIndex: Int) -> Bool {
        false
    }
    
    internal func collapse(for id: AnyHashable, enabled: Bool) {
        items.first { $0.id == id }?.item.animator().isCollapsed = enabled
    }
}
