//
//  UtilityAreaTabViewModel.swift
//  UtilityArea
//
//  Created by Claude on 2/11/25.
//

import SwiftUI

/// View model for managing tabs in the utility area.
public final class UtilityAreaTabViewModel: ObservableObject {
    /// The currently selected tab.
    @Published public var selectedTab: UtilityAreaTab?

    /// The list of available tabs.
    @Published public var tabs: [UtilityAreaTab] = UtilityAreaTab.allCases

    /// Whether the tab bar is visible.
    @Published public var isVisible: Bool = true

    public init() {}

    /// Select a tab.
    /// - Parameter tab: The tab to select.
    public func select(_ tab: UtilityAreaTab?) {
        selectedTab = tab
    }

    /// Toggle the visibility of the tab bar.
    public func toggleVisibility() {
        isVisible.toggle()
    }

    /// Show the tab bar.
    public func show() {
        isVisible = true
    }

    /// Hide the tab bar.
    public func hide() {
        isVisible = false
    }
}
