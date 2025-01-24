import SwiftUI

struct LiveTickerView: View {
    let symbol: String
    @ObservedObject var viewModel: RealTimeMarketViewModel
    
    private var quote: (bid: Double, ask: Double)? {
        viewModel.lastQuotes[symbol]
    }
    
    private var lastTrade: Double? {
        viewModel.lastTrades[symbol]
    }
    
    var body: some View {
        HStack {
            Text(symbol)
                .font(.headline)
            
            Spacer()
            
            if let quote = quote {
                VStack(alignment: .trailing) {
                    if let trade = lastTrade {
                        Text(String(format: "%.2f", trade))
                            .font(.headline)
                            .foregroundColor(.primary)
                    }
                    
                    HStack(spacing: 12) {
                        Text("B: \(String(format: "%.2f", quote.bid))")
                            .foregroundColor(.green)
                        Text("A: \(String(format: "%.2f", quote.ask))")
                            .foregroundColor(.red)
                    }
                    .font(.subheadline)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct LiveTickerListView: View {
    @ObservedObject var viewModel: RealTimeMarketViewModel
    let symbols: [String]
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Live Market Data")
                    .font(.title2)
                    .bold()
                
                Spacer()
                
                // Connection status indicator
                Circle()
                    .fill(viewModel.isConnected ? Color.green : Color.red)
                    .frame(width: 8, height: 8)
            }
            .padding(.horizontal)
            
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(symbols, id: \.self) { symbol in
                        LiveTickerView(symbol: symbol, viewModel: viewModel)
                            .padding(.horizontal)
                            .background(Color(.windowBackgroundColor))
                    }
                }
                .task {
                    await viewModel.subscribeToSymbols(symbols)
                }
            }
            .frame(maxHeight: 200)
            .onDisappear {
                Task {
                    await viewModel.unsubscribeFromSymbols(symbols)
                }
            }
        }
    }
}
