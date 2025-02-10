import SwiftUI

/// A trait key for storing whether a split view item can collapse
@available(macOS 14.0, *)
public struct SplitViewItemCanCollapseViewTraitKey: ViewTraitKey {
    /// The default value for the trait key
    public static let defaultValue: Bool = false
}

/// A trait key for storing whether a split view item is collapsed
@available(macOS 14.0, *)
public struct SplitViewItemCollapsedViewTraitKey: ViewTraitKey {
    /// The default value for the trait key
    public static let defaultValue: Binding<Bool> = .constant(false)
}

/// A trait key for storing the holding priority of a split view item
@available(macOS 14.0, *)
public struct SplitViewHoldingPriorityTraitKey: ViewTraitKey {
    /// The default value for the trait key
    public static let defaultValue: Float = 250
}

@available(macOS 14.0, *)
extension View {
    /// Sets whether this split view item can collapse
    /// - Parameter value: Whether the item can collapse
    /// - Returns: A modified view with the collapse trait set
    public func canCollapse(_ value: Bool) -> some View {
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
    public func holdingPriority(_ value: Float) -> some View {
        _trait(SplitViewHoldingPriorityTraitKey.self, value)
    }
}
