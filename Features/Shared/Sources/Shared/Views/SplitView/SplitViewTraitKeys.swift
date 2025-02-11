import SwiftUI

public struct SplitViewControllerLayoutValueKey: _ViewTraitKey {
    public static var defaultValue: () -> SplitViewController? = { nil }
}

public struct SplitViewItemCollapsedViewTraitKey: _ViewTraitKey {
    public static var defaultValue: Binding<Bool> = .constant(false)
}

public struct SplitViewItemCanCollapseViewTraitKey: _ViewTraitKey {
    public static var defaultValue: Bool = false
}

public struct SplitViewHoldingPriorityTraitKey: _ViewTraitKey {
    public static var defaultValue: NSLayoutConstraint.Priority = .defaultLow
}

extension View {
    /// Sets whether the view is collapsed
    public func collapsed(_ value: Binding<Bool>) -> some View {
        self._trait(SplitViewItemCollapsedViewTraitKey.self, .init {
            value.wrappedValue
        } set: {
            value.wrappedValue = $0
        })
    }

    /// Sets whether the view can be collapsed
    public func canCollapse() -> some View {
        self._trait(SplitViewItemCanCollapseViewTraitKey.self, true)
    }

    /// Sets the holding priority for the view
    public func holdingPriority(_ priority: NSLayoutConstraint.Priority) -> some View {
        self._trait(SplitViewHoldingPriorityTraitKey.self, priority)
    }
}
