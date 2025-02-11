import SwiftUI

/// View model for managing utility area tab state
public class UtilityAreaTabViewModel: ObservableObject {
    /// Whether the leading sidebar is collapsed
    @Published public var leadingSidebarIsCollapsed: Bool = false
    
    /// Whether the trailing sidebar is collapsed
    @Published public var trailingSidebarIsCollapsed: Bool = false
    
    /// Whether the tab has a leading sidebar
    @Published public var hasLeadingSidebar: Bool = false
    
    /// Whether the tab has a trailing sidebar
    @Published public var hasTrailingSidebar: Bool = false
    
    public init(
        leadingSidebarIsCollapsed: Bool = false,
        trailingSidebarIsCollapsed: Bool = false,
        hasLeadingSidebar: Bool = false,
        hasTrailingSidebar: Bool = false
    ) {
        self.leadingSidebarIsCollapsed = leadingSidebarIsCollapsed
        self.trailingSidebarIsCollapsed = trailingSidebarIsCollapsed
        self.hasLeadingSidebar = hasLeadingSidebar
        self.hasTrailingSidebar = hasTrailingSidebar
    }
}
