import SwiftUI

internal struct SplitViewControllerLayoutValueKey: _ViewTraitKey {
    internal static var defaultValue: () -> SplitViewController? = { nil }
}

internal struct SplitViewItemCollapsedViewTraitKey: _ViewTraitKey {
    internal static var defaultValue: Binding<Bool> = .constant(false)
}

internal struct SplitViewItemCanCollapseViewTraitKey: _ViewTraitKey {
    internal static var defaultValue: Bool = false
}

internal struct SplitViewHoldingPriorityTraitKey: _ViewTraitKey {
    internal static var defaultValue: NSLayoutConstraint.Priority = .defaultLow
}

public extension View {
    /// Collapses or expands this view in its parent split view
    /// - Parameter value: Binding to control the collapsed state
    /// - Returns: A modified view that can be collapsed/expanded
    func collapsed(_ value: Binding<Bool>) -> some View {
        self
            ._trait(SplitViewItemCollapsedViewTraitKey.self, value)
    }
    
    /// Makes this view collapsible in its parent split view
    /// - Returns: A modified view that can be collapsed
    func collapsible() -> some View {
        self
            ._trait(SplitViewItemCanCollapseViewTraitKey.self, true)
    }
    
    /// Sets the holding priority for this view in its parent split view
    /// - Parameter priority: The NSLayoutConstraint.Priority to use
    /// - Returns: A modified view with the specified holding priority
    func holdingPriority(_ priority: NSLayoutConstraint.Priority) -> some View {
        self
            ._trait(SplitViewHoldingPriorityTraitKey.self, priority)
    }
}
