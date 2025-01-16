import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var appViewModel: AppViewModel
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 20) {
                PortfolioSummaryCard()
                MarketOverviewCard()
                RecentTradesCard()
                AIInsightsCard()
            }
            .padding()
        }
    }
}

struct PortfolioSummaryCard: View {
    var body: some View {
        GroupBox("Portfolio Summary") {
            VStack(alignment: .leading, spacing: 10) {
                Text("Total Value: $100,000")
                    .font(.headline)
                Text("Daily Change: +$1,500 (1.5%)")
                    .foregroundColor(.green)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
    }
}

struct MarketOverviewCard: View {
    var body: some View {
        GroupBox("Market Overview") {
            VStack(alignment: .leading, spacing: 10) {
                Text("S&P 500: 4,500 (+0.5%)")
                Text("NASDAQ: 15,000 (+0.7%)")
                Text("DOW: 35,000 (+0.3%)")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
    }
}

struct RecentTradesCard: View {
    var body: some View {
        GroupBox("Recent Trades") {
            List {
                ForEach(1...5, id: \.self) { _ in
                    HStack {
                        Text("AAPL")
                        Spacer()
                        Text("Buy")
                            .foregroundColor(.green)
                        Text("100 shares")
                        Text("$150.00")
                    }
                }
            }
            .frame(height: 200)
        }
    }
}

struct AIInsightsCard: View {
    var body: some View {
        GroupBox("AI Insights") {
            VStack(alignment: .leading, spacing: 10) {
                Text("Market Sentiment: Bullish")
                    .font(.headline)
                Text("Recommended Actions:")
                    .font(.subheadline)
                Text("• Consider increasing position in technology sector")
                Text("• Monitor inflation data release tomorrow")
                Text("• Review portfolio allocation")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
    }
}

struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardView()
            .environmentObject(AppViewModel())
    }
}
