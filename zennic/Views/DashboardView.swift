import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var appViewModel: AppViewModel
    @State private var selectedSymbol: String?
    @State private var selectedChartPeriod: ChartTimePeriod = .day
    
    // Default symbols to track
    private let watchlistSymbols = ["AAPL", "MSFT", "GOOGL", "AMZN", "META"]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Portfolio value and performance
                VStack(spacing: 0) {
                    PortfolioValueView(viewModel: appViewModel.realTimeMarket)
                        .frame(maxWidth: .infinity)
                    
                    // Portfolio performance chart
                    GroupBox {
                        VStack {
                            Picker("Time Period", selection: $selectedChartPeriod) {
                                ForEach(ChartTimePeriod.allCases, id: \.self) { period in
                                    Text(period.rawValue).tag(period)
                                }
                            }
                            .pickerStyle(.segmented)
                            .padding(.horizontal)
                            
                            if appViewModel.realTimeMarket.isLoadingHistoricalData {
                                ProgressView()
                                    .frame(height: 300)
                            } else {
                                PortfolioChartView(
                                    pricePoints: appViewModel.realTimeMarket.portfolioHistory
                                )
                                .frame(height: 300)
                            }
                        }
                    }
                    .padding(.top)
                }
                
                // Market overview with live tickers
                GroupBox(label: Text("Market Overview").font(.headline)) {
                    LiveTickerListView(
                        viewModel: appViewModel.realTimeMarket,
                        symbols: watchlistSymbols
                    )
                    .frame(height: 200)
                }
                
                // Stock chart for selected symbol
                if let symbol = selectedSymbol,
                   let candleData = appViewModel.realTimeMarket.candleStickData[symbol] {
                    GroupBox(label: Text("\(symbol) Chart").font(.headline)) {
                        VStack {
                            if appViewModel.realTimeMarket.isLoadingHistoricalData {
                                ProgressView()
                                    .frame(height: 300)
                            } else {
                                StockChartView(
                                    candleStickData: candleData,
                                    volumeData: candleData.map {
                                        VolumeData(
                                            date: $0.date,
                                            volume: $0.volume,
                                            isUpDay: $0.close >= $0.open
                                        )
                                    }
                                )
                                .frame(height: 300)
                            }
                        }
                    }
                }
                
                // Recent trade updates
                GroupBox(label: Text("Recent Activity").font(.headline)) {
                    ForEach(appViewModel.realTimeMarket.tradeUpdates.prefix(5), id: \.self) { update in
                        Text(update)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.vertical, 4)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Dashboard")
        .onChange(of: selectedChartPeriod) { newPeriod in
            Task {
                await appViewModel.realTimeMarket.loadPortfolioHistory(for: newPeriod)
            }
        }
        .onAppear {
            // Load initial data
            Task {
                await appViewModel.realTimeMarket.loadPortfolioHistory(for: selectedChartPeriod)
                await appViewModel.realTimeMarket.loadHistoricalData(for: watchlistSymbols)
            }
        }
    }
}

struct PortfolioValueView: View {
    let viewModel: RealTimeMarket
    
    var body: some View {
        GroupBox("Portfolio Value") {
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

struct LiveTickerListView: View {
    let viewModel: RealTimeMarket
    let symbols: [String]
    
    var body: some View {
        List {
            ForEach(symbols, id: \.self) { symbol in
                HStack {
                    Text(symbol)
                    Spacer()
                    Text(viewModel.getQuote(for: symbol))
                }
            }
        }
    }
}

struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardView()
            .environmentObject(AppViewModel())
    }
}
