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
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(symbol)
                    .font(.headline)
                
                Spacer()
                
                if let trade = lastTrade {
                    Text(String(format: "%.2f", trade))
                        .font(.headline)
                        .foregroundColor(.primary)
                }
            }
            
            if let quote = quote {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Bid")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(String(format: "%.2f", quote.bid))
                            .font(.subheadline)
                            .foregroundColor(.green)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text("Ask")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(String(format: "%.2f", quote.ask))
                            .font(.subheadline)
                            .foregroundColor(.red)
                    }
                }
            }
        }
        .padding()
        .background(Color(.windowBackgroundColor))
        .cornerRadius(8)
        .shadow(radius: 2)
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
                LazyVStack(spacing: 8) {
                    ForEach(symbols, id: \.self) { symbol in
                        LiveTickerView(symbol: symbol, viewModel: viewModel)
                    }
                }
                .padding(.horizontal)
            }
        }
        .onAppear {
            viewModel.subscribeToSymbols(symbols)
        }
        .onDisappear {
            viewModel.unsubscribeFromSymbols(symbols)
        }
    }
}
