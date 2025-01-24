import SwiftUI

/// Represents the main navigation sections of the application.
/// Each case corresponds to a different view that can be displayed in the main content area.
enum NavigationItem: Hashable {
    /// Main dashboard showing overview of portfolio and market data
    case dashboard
    /// Detailed view of user's portfolio and positions
    case portfolio
    /// Trading interface for executing orders
    case trading
    /// Market analysis and research tools
    case analysis
    /// Application settings and configuration
    case settings
    
    /// The display title for each navigation item
    var title: String {
        switch self {
        case .dashboard: return "Dashboard"
        case .portfolio: return "Portfolio"
        case .trading: return "Trading"
        case .analysis: return "Analysis"
        case .settings: return "Settings"
        }
    }
    
    /// The SF Symbol name used as an icon for each navigation item
    var icon: String {
        switch self {
        case .dashboard: return "chart.line.uptrend.xyaxis"
        case .portfolio: return "briefcase"
        case .trading: return "arrow.left.arrow.right"
        case .analysis: return "magnifyingglass"
        case .settings: return "gear"
        }
    }
}
