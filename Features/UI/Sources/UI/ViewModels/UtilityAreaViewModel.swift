import SwiftUI

/// Manages the state of the utility area.
public final class UtilityAreaViewModel: ObservableObject {
    /// Whether the utility area is collapsed.
    @Published public var isCollapsed = true
    
    /// Whether the utility area is maximized.
    @Published public var isMaximized = false
    
    /// The currently selected tab.
    @Published public var selectedTab: UtilityAreaTab = .terminal
    
    /// Toggles the collapsed state of the utility area.
    public func toggleCollapsed() {
        if isMaximized {
            isMaximized = false
        }
        isCollapsed.toggle()
    }
    
    /// Toggles the maximized state of the utility area.
    public func toggleMaximized() {
        if isCollapsed {
            isCollapsed = false
        }
        isMaximized.toggle()
    }
    
    /// Creates a new utility area view model.
    public init() {}
}

/// A key for accessing the utility area view model in the environment.
private struct UtilityAreaViewModelKey: EnvironmentKey {
    static let defaultValue = UtilityAreaViewModel()
}

extension EnvironmentValues {
    /// The utility area view model.
    public var utilityAreaViewModel: UtilityAreaViewModel {
        get { self[UtilityAreaViewModelKey.self] }
        set { self[UtilityAreaViewModelKey.self] = newValue }
    }
}
