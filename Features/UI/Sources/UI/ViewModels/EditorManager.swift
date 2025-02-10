import SwiftUI
import Combine

/// Manages the state and operations for editor tabs
@MainActor public final class EditorManager: ObservableObject {
    /// Currently opened tabs
    @Published public private(set) var tabs: [EditorTab] = []
    
    /// Currently selected tab
    @Published public private(set) var selectedTab: EditorTab?
    
    /// Temporary tab that will be replaced when a new tab is opened
    @Published public private(set) var temporaryTab: EditorTab?
    
    /// Opens a new tab
    /// - Parameter tab: The tab to open
    public func openTab(_ tab: EditorTab) {
        if let temporaryTab = temporaryTab {
            // Replace temporary tab
            if let index = tabs.firstIndex(where: { $0.id == temporaryTab.id }) {
                tabs[index] = tab
            }
            self.temporaryTab = nil
        } else if !tabs.contains(tab) {
            tabs.append(tab)
        }
        selectedTab = tab
    }
    
    /// Opens a temporary tab that will be replaced when a new tab is opened
    /// - Parameter tab: The temporary tab
    public func openTemporaryTab(_ tab: EditorTab) {
        temporaryTab = tab
        if !tabs.contains(tab) {
            tabs.append(tab)
        }
        selectedTab = tab
    }
    
    /// Closes a tab
    /// - Parameter tab: The tab to close
    public func closeTab(_ tab: EditorTab) {
        if tab.id == temporaryTab?.id {
            temporaryTab = nil
        }
        tabs.removeAll(where: { $0.id == tab.id })
        if selectedTab?.id == tab.id {
            selectedTab = tabs.last
        }
    }
    
    /// Selects a tab
    /// - Parameter tab: The tab to select
    public func selectTab(_ tab: EditorTab) {
        selectedTab = tab
    }
    
    /// Reorders tabs
    /// - Parameter orderedTabs: The new order of tabs
    public func reorderTabs(_ orderedTabs: [EditorTab]) {
        tabs = orderedTabs
    }
    
    /// Creates a new untitled tab
    public func createUntitledTab() {
        let id = EditorTabID.untitled(UUID())
        let tab = EditorTab(id: id, name: "Untitled")
        openTab(tab)
    }
}
