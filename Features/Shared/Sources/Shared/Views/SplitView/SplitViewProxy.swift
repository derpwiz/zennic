import SwiftUI

/// A proxy for controlling a split view controller
@available(macOS 14.0, *)
public final class SplitViewProxy: Observable {
    /// The view controller closure
    private let viewController: () -> SplitViewController?
    
    /// Creates a new split view proxy
    /// - Parameter viewController: A closure that returns the split view controller
    public init(viewController: @escaping () -> SplitViewController?) {
        self.viewController = viewController
    }
    
    /// Sets the position of a split view item
    /// - Parameters:
    ///   - index: The index of the item
    ///   - position: The new position
    public func setPosition(of index: Int, position: CGFloat) {
        viewController()?.setPosition(of: index, position: position)
    }
}
