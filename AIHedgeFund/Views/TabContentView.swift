import SwiftUI

struct TabContentView: View {
    let selectedTab: NavigationItem
    
    var body: some View {
        Group {
            switch selectedTab {
            case .dashboard:
                DashboardView()
            case .portfolio:
                PortfolioView()
            case .trading:
                TradingView()
            case .analysis:
                AnalysisView()
            case .settings:
                SettingsView()
            }
        }
    }
}

struct TabContentView_Previews: PreviewProvider {
    static var previews: some View {
        TabContentView(selectedTab: .dashboard)
    }
}
