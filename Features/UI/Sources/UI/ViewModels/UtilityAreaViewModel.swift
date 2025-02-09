import SwiftUI

/// Manages the state of the utility area.
public final class UtilityAreaViewModel: ObservableObject {
    /// The default height of the utility area
    public static let defaultHeight: CGFloat = 300
    
    /// The minimum height of the utility area
    public static let minHeight: CGFloat = 100
    
    /// The maximum height of the utility area
    public static let maxHeight: CGFloat = 800
    
    /// Whether the utility area is collapsed
    @Published public var isCollapsed = true
    
    /// Whether the utility area is maximized
    @Published public var isMaximized = false
    
    /// The currently selected tab
    @Published public var selectedTab: UtilityAreaTab = .terminal
    
    /// The current height of the utility area
    @Published public var height: CGFloat = defaultHeight
    
    /// The height before maximizing
    private var previousHeight: CGFloat = defaultHeight
    
    /// Toggles the collapsed state of the utility area
    public func togglePanel() {
        if isMaximized {
            isMaximized = false
            height = previousHeight
        }
        isCollapsed.toggle()
    }
    
    /// Toggles the maximized state of the utility area
    public func toggleMaximized() {
        if isCollapsed {
            isCollapsed = false
        }
        
        if isMaximized {
            height = previousHeight
        } else {
            previousHeight = height
            height = maxHeight
        }
        
        isMaximized.toggle()
    }
    
    /// Updates the height of the utility area
    /// - Parameter newHeight: The new height
    public func updateHeight(_ newHeight: CGFloat) {
        if !isMaximized {
            height = min(max(newHeight, minHeight), maxHeight)
        }
    }
    
    /// Creates a new utility area view model
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
