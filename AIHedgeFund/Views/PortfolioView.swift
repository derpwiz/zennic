import SwiftUI
import Charts

struct PortfolioView: View {
    @EnvironmentObject private var appViewModel: AppViewModel
    @State private var selectedHolding: PortfolioHolding?
    @State private var showingAddHoldingSheet = false
    
    var body: some View {
        VStack {
            HStack {
                Text("Portfolio")
                    .font(.title)
                Spacer()
                Button(action: { showingAddHoldingSheet = true }) {
                    Label("Add Holding", systemImage: "plus")
                }
            }
            .padding()
            
            Table(appViewModel.holdings) {
                TableColumn("Symbol", value: \.symbol)
                TableColumn("Shares") { (holding: PortfolioHolding) in
                    Text(String(format: "%.2f", holding.shares))
                }
                TableColumn("Purchase Price") { (holding: PortfolioHolding) in
                    Text(String(format: "$%.2f", holding.purchasePrice))
                }
                TableColumn("Total Cost") { (holding: PortfolioHolding) in
                    let totalCost = holding.shares * holding.purchasePrice
                    Text(String(format: "$%.2f", totalCost))
                }
                TableColumn("Date") { (holding: PortfolioHolding) in
                    Text(holding.purchaseDate, style: .date)
                }
            }
            .padding()
        }
        .sheet(isPresented: $showingAddHoldingSheet) {
            AddHoldingView(appViewModel: appViewModel)
        }
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
                            let holding = PortfolioHolding(
                                id: UUID(),
                                symbol: symbol.uppercased(),
                                shares: shares,
                                purchasePrice: price,
                                purchaseDate: Date()
                            )
                            appViewModel.addHolding(holding)
                            dismiss()
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
