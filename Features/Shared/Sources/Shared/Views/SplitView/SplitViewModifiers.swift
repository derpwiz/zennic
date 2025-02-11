import SwiftUI

struct SplitViewControllerLayoutValueKey: _ViewTraitKey {
    static var defaultValue: () -> SplitViewController? = { nil }
}

struct SplitViewItemCollapsedViewTraitKey: _ViewTraitKey {
    static var defaultValue: Binding<Bool> = .constant(false)
}

struct SplitViewItemCanCollapseViewTraitKey: _ViewTraitKey {
    static var defaultValue: Bool = false
}

struct SplitViewHoldingPriorityTraitKey: _ViewTraitKey {
    static var defaultValue: NSLayoutConstraint.Priority = .defaultLow
}

extension View {
    /// Sets whether the view can be collapsed
    public func canCollapse() -> some View {
        self._trait(SplitViewItemCanCollapseViewTraitKey.self, true)
    }
    
    /// Sets whether the view is collapsed
    public func collapsed(_ value: Binding<Bool>) -> some View {
        self._trait(SplitViewItemCollapsedViewTraitKey.self, value)
    }
    
    /// Sets the holding priority for the view
    public func holdingPriority(_ priority: NSLayoutConstraint.Priority) -> some View {
        self._trait(SplitViewHoldingPriorityTraitKey.self, priority)
    }
}
