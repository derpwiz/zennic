import SwiftUI

/// A trait key for storing whether a split view item can collapse
public struct SplitViewItemCanCollapseViewTraitKey: _ViewTraitKey {
    public static var defaultValue: Bool = false
}

/// A trait key for storing whether a split view item is collapsed
public struct SplitViewItemCollapsedViewTraitKey: _ViewTraitKey {
    public static var defaultValue: Binding<Bool> = .constant(false)
}

/// A trait key for storing the holding priority of a split view item
public struct SplitViewHoldingPriorityTraitKey: _ViewTraitKey {
    public static var defaultValue: NSLayoutConstraint.Priority = .defaultLow
}

extension View {
    /// Sets whether this split view item can collapse
    /// - Parameter value: Whether the item can collapse
    /// - Returns: A modified view with the collapse trait set
    public func canCollapse(_ value: Bool = true) -> some View {
        _trait(SplitViewItemCanCollapseViewTraitKey.self, value)
    }
    
    /// Sets whether this split view item is collapsed
    /// - Parameter value: A binding to whether the item is collapsed
    /// - Returns: A modified view with the collapsed trait set
    public func collapsed(_ value: Binding<Bool>) -> some View {
        _trait(SplitViewItemCollapsedViewTraitKey.self, value)
    }
    
    /// Sets the holding priority of this split view item
    /// - Parameter value: The holding priority
    /// - Returns: A modified view with the holding priority trait set
    public func holdingPriority(_ value: NSLayoutConstraint.Priority) -> some View {
        _trait(SplitViewHoldingPriorityTraitKey.self, value)
    }
    
    /// Sets the holding priority of this split view item using a raw value
    /// - Parameter value: The holding priority as a Float
    /// - Returns: A modified view with the holding priority trait set
    public func holdingPriority(_ value: Float) -> some View {
        holdingPriority(NSLayoutConstraint.Priority(value))
    }
}
