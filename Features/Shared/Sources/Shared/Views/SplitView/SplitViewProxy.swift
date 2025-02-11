import SwiftUI

/// A proxy for controlling a split view controller
public final class SplitViewProxy: ObservableObject {
    /// The view controller closure
    private let viewController: () -> SplitViewControllerProtocol?
    
    /// The current position of the split view items
    @Published public private(set) var positions: [CGFloat] = []
    
    /// Creates a new split view proxy
    /// - Parameter viewController: A closure that returns the split view controller
    public init(viewController: @escaping () -> SplitViewControllerProtocol?) {
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
    
    /// Collapses or expands a split view item
    /// - Parameters:
    ///   - id: The id of the item to collapse
    ///   - enabled: Whether the item should be collapsed
    public func collapse(for id: AnyHashable, enabled: Bool) {
        viewController()?.collapse(for: id, enabled: enabled)
    }
}
