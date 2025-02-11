import SwiftUI

/// View model for managing utility area state
public class UtilityAreaViewModel: ObservableObject {
    /// The currently selected tab
    @Published public var selectedTab: UtilityAreaTab?
    
    /// Whether the utility area is collapsed
    @Published public var isCollapsed: Bool = true
    
    /// Whether the utility area is maximized
    @Published public var isMaximized: Bool = false
    
    /// The tab view model for the current tab
    @Published public var tabViewModel = UtilityAreaTabViewModel()
    
    /// Initialize the view model
    public init(
        selectedTab: UtilityAreaTab? = nil,
        isCollapsed: Bool = true,
        isMaximized: Bool = false
    ) {
        self.selectedTab = selectedTab
        self.isCollapsed = isCollapsed
        self.isMaximized = isMaximized
    }
    
    /// Toggle the collapsed state of the utility area
    public func toggleCollapsed() {
        isCollapsed.toggle()
        if isCollapsed {
            isMaximized = false
        }
    }
    
    /// Toggle the maximized state of the utility area
    public func toggleMaximized() {
        isMaximized.toggle()
        if isMaximized {
            isCollapsed = false
        }
    }
    
    /// Select a specific tab
    public func selectTab(_ tab: UtilityAreaTab?) {
        selectedTab = tab
        if tab != nil && isCollapsed {
            isCollapsed = false
        }
    }
}
