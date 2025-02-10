import SwiftUI

/// Protocol defining the public interface for split view items
public protocol SplitViewItemProtocol {
    /// Unique identifier for the item
    var id: AnyHashable { get }
    
    /// Whether the item is currently collapsed
    var isCollapsed: Bool { get }
    
    /// Whether the item can be collapsed
    var canCollapse: Bool { get }
    
    /// The holding priority of the item
    var holdingPriority: Float? { get }
}
