//
//  NavigatorAreaViewModel.swift
//  zennic
//

import SwiftUI

final class NavigatorAreaViewModel: ObservableObject {
    enum NavigatorTab: Int, CaseIterable {
        case project
        case sourceControl
        case find
        
        var title: String {
            switch self {
            case .project:
                return "Project"
            case .sourceControl:
                return "Source Control"
            case .find:
                return "Find"
            }
        }
        
        var systemImage: String {
            switch self {
            case .project:
                return "folder"
            case .sourceControl:
                return "chevron.left.forwardslash.chevron.right"
            case .find:
                return "magnifyingglass"
            }
        }
    }
    
    @Published var selectedTab: NavigatorTab = .project
    @Published var isCollapsed: Bool = false
    
    // Project navigator state
    @Published var expandedItems: Set<String> = []
    @Published var selectedItems: Set<String> = []
    
    // Find navigator state
    @Published var searchText: String = ""
    @Published var isSearching: Bool = false
    @Published var searchResults: [String] = []
    
    // Source Control navigator state
    @Published var selectedBranch: String = "main"
    @Published var changedFiles: [String] = []
    
    init() {}
    
    func toggleItem(_ identifier: String) {
        if expandedItems.contains(identifier) {
            expandedItems.remove(identifier)
        } else {
            expandedItems.insert(identifier)
        }
    }
    
    func selectItem(_ identifier: String) {
        selectedItems = [identifier]
    }
    
    func clearSelection() {
        selectedItems.removeAll()
    }
    
    func startSearch() {
        isSearching = true
    }
    
    func stopSearch() {
        isSearching = false
        searchText = ""
        searchResults.removeAll()
    }
    
    func updateSearchResults(_ results: [String]) {
        searchResults = results
    }
    
    func updateChangedFiles(_ files: [String]) {
        changedFiles = files
    }
    
    func updateBranch(_ branch: String) {
        selectedBranch = branch
    }
}
