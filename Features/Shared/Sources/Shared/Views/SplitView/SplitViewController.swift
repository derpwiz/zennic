import SwiftUI

public class SplitViewController: NSViewController {
    public var splitView: NSSplitView {
        view as! NSSplitView
    }

    public var items: [SplitViewItem] = []
    public var splitViewItems: [NSSplitViewItem] = []

    private var parentView: SplitViewControllerView
    private var axis: Axis

    public init(parent: SplitViewControllerView, axis: Axis) {
        self.parentView = parent
        self.axis = axis
        super.init(nibName: nil, bundle: nil)
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func loadView() {
        let splitView = NSSplitView()
        splitView.isVertical = axis == .horizontal
        splitView.dividerStyle = .thin
        view = splitView
    }

    public func collapse(for id: AnyHashable, enabled: Bool) {
        guard let item = items.first(where: { $0.id == id }) else { return }
        item.item.animator().isCollapsed = enabled
    }
}
