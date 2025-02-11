import SwiftUI

/// A proxy for controlling a split view controller
public final class SplitViewProxy: ObservableObject {
    /// The view controller closure
    private let viewController: () -> SplitViewController?
    
    /// The current position of the split view items
    @Published public private(set) var positions: [CGFloat] = []
    
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
        if index < positions.count {
            positions[index] = position
        } else {
            positions.append(position)
        }
    }
}
