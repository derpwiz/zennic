import SwiftUI
import Charts

struct TabContentView: View {
    @Binding var selectedTab: NavigationItem
    
    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "chart.bar.fill")
                }
                .tag(NavigationItem.dashboard)
            
            PortfolioView()
                .tabItem {
                    Label("Portfolio", systemImage: "briefcase.fill")
                }
                .tag(NavigationItem.portfolio)
            
            TradingView()
                .tabItem {
                    Label("Trading", systemImage: "dollarsign.circle.fill")
                }
                .tag(NavigationItem.trading)
            
            AnalysisView()
                .tabItem {
                    Label("Analysis", systemImage: "chart.xyaxis.line")
                }
                .tag(NavigationItem.analysis)
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(NavigationItem.settings)
        }
    }
}

struct TabContentView_Previews: PreviewProvider {
    static var previews: some View {
        TabContentView(selectedTab: .constant(.dashboard))
    }
}
