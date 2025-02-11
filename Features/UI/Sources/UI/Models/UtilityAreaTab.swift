import SwiftUI

/// Represents the different tabs in the utility area
public enum UtilityAreaTab: String, CaseIterable, Hashable, WorkspacePanelTab {
    case output = "Output"
    case debug = "Debug"
    case terminal = "Terminal"
    
    public var id: Self { self }
    
    /// The display name of the tab
    public var title: String { rawValue }
    
    /// The SF Symbol name for the tab's icon
    public var systemImage: String {
        switch self {
        case .output: return "list.bullet.indent"
        case .debug: return "ladybug"
        case .terminal: return "terminal"
        }
    }
    
    public var body: some View {
        switch self {
        case .terminal:
            UtilityAreaTerminalView()
        case .debug:
            UtilityAreaDebugView()
        case .output:
            UtilityAreaOutputView()
        }
    }
}
