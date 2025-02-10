import SwiftUI

final class SplitViewController: NSSplitViewController {
    var items: [SplitViewItem] = []
    var axis: Axis
    var parentView: SplitViewControllerView

    init(parent: SplitViewControllerView, axis: Axis = .horizontal) {
        self.axis = axis
        self.parentView = parent
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        splitView.isVertical = axis != .vertical
        splitView.dividerStyle = .thin
        DispatchQueue.main.async { [weak self] in
            self?.parentView.viewController = { [weak self] in
                self
            }
        }
    }

    override func splitView(_ splitView: NSSplitView, shouldHideDividerAt dividerIndex: Int) -> Bool {
        false
    }

    func collapse(for id: AnyHashable, enabled: Bool) {
        items.first { $0.id == id }?.item.animator().isCollapsed = enabled
    }
    
    func setPosition(of index: Int, position: CGFloat) {
        guard index < splitView.arrangedSubviews.count else { return }
        let view = splitView.arrangedSubviews[index]
        if axis == .vertical {
            view.frame.origin.y = position
        } else {
            view.frame.origin.x = position
        }
        splitView.adjustSubviews()
    }
}
