import SwiftUI

/// A preference key for storing the split view controller
public struct SplitViewControllerLayoutValueKey: PreferenceKey {
    /// The value type for the preference key
    public typealias Value = (() -> SplitViewControllerProtocol?)?
    
    /// The default value for the preference key
    public static var defaultValue: Value = nil
    
    /// Combines two values into one
    public static func reduce(value: inout Value, nextValue: () -> Value) {
        value = nextValue()
    }
}

extension View {
    /// Sets the split view controller for this view
    /// - Parameter value: A closure that returns the split view controller
    /// - Returns: A modified view with the split view controller set
    public func splitViewController(_ value: @escaping () -> SplitViewControllerProtocol?) -> some View {
        preference(key: SplitViewControllerLayoutValueKey.self, value: value)
    }
}
