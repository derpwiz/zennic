import SwiftUI
import Foundation

struct DashboardView: View {
    @EnvironmentObject private var appViewModel: AppViewModel
    @State private var selectedSymbol: String?
    @State private var selectedChartPeriod: ChartTimePeriod = .day
    // Default symbols to track
    private let watchlistSymbols = ["AAPL", "GOOGL", "AMZN"] // Example symbols

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                portfolioSection
                marketOverviewSection
                if let symbol = selectedSymbol {
                    stockChartSection(for: symbol)
                }
                recentActivitySection
            }
            .padding()
        }
        .navigationTitle("Dashboard")
        .task {
            await loadData()
        }
        .onChange(of: selectedChartPeriod) { oldValue, newValue in
            Task {
                await loadData()
            }
        }
    }

    // MARK: - View Components
    private var portfolioSection: some View {
        VStack(spacing: 0) {
            PortfolioValueView(viewModel: appViewModel.realTimeMarketViewModel)
                .frame(maxWidth: .infinity)
            GroupBox {
                VStack {
                    periodPicker
                    chartContent
                }
            }
            .padding(.top)
        }
    }

    private var periodPicker: some View {
        Picker("Time Period", selection: $selectedChartPeriod) {
            ForEach(ChartTimePeriod.allCases, id: \.self) { period in
                Text(period.rawValue).tag(period)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
    }

    @ViewBuilder
    private var chartContent: some View {
        if appViewModel.realTimeMarketViewModel.isLoadingHistoricalData {
            ProgressView()
                .frame(height: 300)
        } else {
            PortfolioChartView(
                pricePoints: appViewModel.realTimeMarketViewModel.portfolioHistory
            )
            .frame(height: 300)
        }
    }

    private var marketOverviewSection: some View {
        GroupBox {
            LiveTickerListView(
                viewModel: appViewModel.realTimeMarketViewModel,
                symbols: watchlistSymbols
            )
        } label: {
            Text("Market Overview")
                .font(.headline)
        }
    }

    private func stockChartSection(for symbol: String) -> some View {
        Group {
            if let candleData = appViewModel.realTimeMarketViewModel.candleStickData[symbol] {
                GroupBox {
                    VStack(alignment: .leading) {
                        stockChartContent(candleData: candleData)
                    }
                } label: {
                    Text("\(symbol) Chart")
                        .font(.headline)
                }
            } else {
                Color.clear
            }
        }
    }

    @ViewBuilder
    private func stockChartContent(candleData: [StockBarData]) -> some View {
        if appViewModel.realTimeMarketViewModel.isLoadingHistoricalData {
            ProgressView()
                .frame(height: 300)
        } else {
            StockChartView(
                candleStickData: candleData,
                volumeData: candleData.map {
                    VolumeData(
                        date: $0.timestamp,
                        volume: $0.volume,
                        isUp: $0.isUpward
                    )
                }
            )
            .frame(height: 300)
        }
    }

    private var recentActivitySection: some View {
        GroupBox {
            ForEach(appViewModel.realTimeMarketViewModel.tradeUpdates.prefix(5), id: \.self) { update in
                Text(update)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 4)
            }
        } label: {
            Text("Recent Activity")
                .font(.headline)
        }
    }

    private func loadData() async {
        await appViewModel.realTimeMarketViewModel.loadHistoricalData(for: watchlistSymbols)
    }
}

struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardView()
            .environmentObject(AppViewModel())
    }
}
