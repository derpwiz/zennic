import SwiftUI
import Charts

struct PortfolioView: View {
    @EnvironmentObject private var appViewModel: AppViewModel
    @State private var selectedHolding: PortfolioHolding?
    @State private var showingAddHoldingSheet = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Portfolio summary with real-time value
            PortfolioValueView(viewModel: appViewModel.realTimeMarket)
                .frame(maxWidth: .infinity)
            
            // Holdings list with real-time prices
            List {
                ForEach(appViewModel.holdings) { holding in
                    HoldingRow(
                        holding: holding,
                        currentPrice: appViewModel.realTimeMarket.lastTrades[holding.symbol] ?? holding.averagePrice
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedHolding = holding
                    }
                }
            }
            .listStyle(.inset)
        }
        .padding()
        .navigationTitle("Portfolio")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showingAddHoldingSheet = true }) {
                    Label("Add Holding", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddHoldingSheet) {
            AddHoldingView(appViewModel: appViewModel)
        }
        .sheet(item: $selectedHolding) { holding in
            HoldingDetailView(holding: holding)
        }
        .onAppear {
            // Subscribe to real-time updates for all holdings
            let symbols = appViewModel.holdings.map(\.symbol)
            appViewModel.realTimeMarket.subscribeToSymbols(symbols)
        }
        .onDisappear {
            // Unsubscribe when view disappears
            let symbols = appViewModel.holdings.map(\.symbol)
            appViewModel.realTimeMarket.unsubscribeFromSymbols(symbols)
        }
    }
}

struct HoldingRow: View {
    let holding: PortfolioHolding
    let currentPrice: Double
    
    private var priceChange: Double {
        currentPrice - holding.averagePrice
    }
    
    private var percentageChange: Double {
        (priceChange / holding.averagePrice) * 100
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(holding.symbol)
                    .font(.headline)
                Text("\(holding.shares) shares")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Text(String(format: "$%.2f", currentPrice))
                    .font(.headline)
                
                Text(String(format: "%.2f%%", percentageChange))
                    .font(.subheadline)
                    .foregroundColor(percentageChange >= 0 ? .green : .red)
            }
        }
        .padding(.vertical, 4)
    }
}

struct AddHoldingView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var appViewModel: AppViewModel
    @State private var symbol = ""
    @State private var shares = ""
    @State private var purchasePrice = ""
    
    var body: some View {
        NavigationStack {
            Form {
                TextField("Symbol", text: $symbol)
                TextField("Number of Shares", text: $shares)
                TextField("Purchase Price", text: $purchasePrice)
            }
            .navigationTitle("Add Holding")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        if let shares = Double(shares),
                           let price = Double(purchasePrice) {
                            do {
                                let holding = try PortfolioHolding(
                                    id: UUID(),
                                    symbol: symbol.uppercased(),
                                    shares: shares,
                                    purchasePrice: price,
                                    purchaseDate: Date()
                                )
                                appViewModel.addHolding(holding)
                                dismiss()
                            } catch {
                                print("Error creating holding: \(error)")
                            }
                        }
                    }
                    .disabled(symbol.isEmpty || shares.isEmpty || purchasePrice.isEmpty)
                }
            }
        }
        .frame(width: 400, height: 300)
    }
}

struct PortfolioView_Previews: PreviewProvider {
    static var previews: some View {
        PortfolioView()
            .environmentObject(AppViewModel())
    }
}
