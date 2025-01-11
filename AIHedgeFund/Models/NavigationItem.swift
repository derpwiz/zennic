import SwiftUI

enum NavigationItem: Hashable {
    case dashboard
    case portfolio
    case trading
    case analysis
    case settings
    
    var title: String {
        switch self {
        case .dashboard: return "Dashboard"
        case .portfolio: return "Portfolio"
        case .trading: return "Trading"
        case .analysis: return "Analysis"
        case .settings: return "Settings"
        }
    }
    
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
