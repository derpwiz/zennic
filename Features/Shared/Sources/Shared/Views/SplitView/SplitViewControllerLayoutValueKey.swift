import SwiftUI

/// A layout value key for storing the split view controller
@available(macOS 14.0, *)
public struct SplitViewControllerLayoutValueKey: LayoutValueKey {
    /// The value type for the layout value key
    public static let defaultValue: () -> SplitViewController? = { nil }
}

@available(macOS 14.0, *)
extension View {
    /// Sets the split view controller for this view
    /// - Parameter value: A closure that returns the split view controller
    /// - Returns: A modified view with the split view controller set
    public func splitViewController(_ value: @escaping () -> SplitViewController?) -> some View {
        _trait(SplitViewControllerLayoutValueKey.self, value)
    }
}
