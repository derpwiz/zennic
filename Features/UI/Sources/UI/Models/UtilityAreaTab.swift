import SwiftUI

/// Represents a tab in the utility area.
public enum UtilityAreaTab: String, CaseIterable {
    case output = "Output"
    case debug = "Debug"
    case terminal = "Terminal"
    
    /// The icon associated with this tab.
    public var icon: String {
        switch self {
        case .output:
            return "text.alignleft"
        case .debug:
            return "ladybug"
        case .terminal:
            return "terminal"
        }
    }
    
    /// The display name of this tab.
    public var name: String {
        return rawValue
    }
}
