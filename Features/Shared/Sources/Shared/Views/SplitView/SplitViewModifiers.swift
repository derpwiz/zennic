import SwiftUI

/// View trait key for storing the collapsed state of a split view item
struct SplitViewItemCollapsedViewTraitKey: _ViewTraitKey {
    static var defaultValue: Binding<Bool> = .constant(false)
}

/// View trait key for storing whether a split view item can be collapsed
struct SplitViewItemCanCollapseViewTraitKey: _ViewTraitKey {
    static var defaultValue: Bool = false
}

/// View trait key for storing the holding priority of a split view item
struct SplitViewHoldingPriorityTraitKey: _ViewTraitKey {
    static var defaultValue: NSLayoutConstraint.Priority = .defaultLow
}

/// Extension providing modifiers for configuring split view items
public extension View {
    /// Sets whether the split view item is collapsed
    /// - Parameter value: Binding to the collapsed state
    /// - Returns: A modified view
    func collapsed(_ value: Binding<Bool>) -> some View {
        self._trait(SplitViewItemCollapsedViewTraitKey.self, value)
    }

    /// Makes the split view item collapsible
    /// - Returns: A modified view
    func collapsible() -> some View {
        self._trait(SplitViewItemCanCollapseViewTraitKey.self, true)
    }

    /// Sets the holding priority of the split view item
    /// - Parameter priority: The layout constraint priority
    /// - Returns: A modified view
    func holdingPriority(_ priority: NSLayoutConstraint.Priority) -> some View {
        self._trait(SplitViewHoldingPriorityTraitKey.self, priority)
    }
}
