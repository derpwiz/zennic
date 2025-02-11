import SwiftUI

/// Protocol defining the interface for split view controllers
public protocol SplitViewControllerProtocol: AnyObject {
    var items: [SplitViewItem] { get set }
    var axis: Axis { get }
    
    func setPosition(of index: Int, position: CGFloat)
    func collapse(for id: AnyHashable, enabled: Bool)
}

/// A wrapper that provides a unified interface for split view controllers
public final class SplitViewControllerWrapper: NSObject {
    private let controller: NSSplitViewController
    private let _axis: Axis
    
    public var axis: Axis {
        get { _axis }
    }
    private var _items: [SplitViewItem] = []
    
    public var items: [SplitViewItem] {
        get { _items }
        set {
            _items = newValue
            controller.splitViewItems = newValue.map(\.item)
        }
    }
    
    public init(axis: Axis = .horizontal) {
        self.controller = NSSplitViewController()
        self._axis = axis
        super.init()
        
        controller.splitView.isVertical = _axis != .vertical
        controller.splitView.dividerStyle = .thin
    }
    
    public func setPosition(of index: Int, position: CGFloat) {
        guard index < controller.splitView.arrangedSubviews.count else { return }
        let view = controller.splitView.arrangedSubviews[index]
        if _axis == .vertical {
            view.frame.origin.y = position
        } else {
            view.frame.origin.x = position
        }
        controller.splitView.adjustSubviews()
    }
    
    public func collapse(for id: AnyHashable, enabled: Bool) {
        items.first { $0.id == id }?.item.animator().isCollapsed = enabled
    }
}

extension SplitViewControllerWrapper: SplitViewControllerProtocol {}
