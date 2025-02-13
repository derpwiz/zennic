//
//  UtilityAreaTab.swift
//  UtilityArea
//
//  Created by Claude on 2/11/25.
//

import Foundation
import SwiftUI

/// Represents a tab in the utility area.
public enum UtilityAreaTab: String, CaseIterable {
    case terminal
    case output
    case debug

    /// The title of the tab.
    public var title: String {
        switch self {
        case .terminal:
            return "Terminal"
        case .output:
            return "Output"
        case .debug:
            return "Debug"
        }
    }

    /// The icon for the tab.
    public var icon: String {
        switch self {
        case .terminal:
            return "terminal"
        case .output:
            return "text.alignleft"
        case .debug:
            return "ladybug"
        }
    }

    /// The color for the tab icon.
    public var iconColor: Color {
        switch self {
        case .terminal:
            return .secondary
        case .output:
            return .secondary
        case .debug:
            return .secondary
        }
    }
}
