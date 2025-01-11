import SwiftUI

struct TradingView: View {
    @EnvironmentObject private var appViewModel: AppViewModel
    @State private var symbol = ""
    @State private var orderType: OrderType = .market
    @State private var action: TradeAction = .buy
    @State private var quantity = ""
    @State private var limitPrice = ""
    
    enum OrderType: String, CaseIterable {
        case market = "Market"
        case limit = "Limit"
    }
    
    enum TradeAction: String, CaseIterable {
        case buy = "Buy"
        case sell = "Sell"
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Order Details") {
                    TextField("Symbol", text: $symbol)
                    
                    Picker("Order Type", selection: $orderType) {
                        ForEach(OrderType.allCases, id: \.self) { type in
                            Text(type.rawValue)
                        }
                    }
                    
                    Picker("Action", selection: $action) {
                        ForEach(TradeAction.allCases, id: \.self) { action in
                            Text(action.rawValue)
                        }
                    }
                    
                    TextField("Quantity", text: $quantity)
                    
                    if orderType == .limit {
                        TextField("Limit Price", text: $limitPrice)
                    }
                }
                
                Section("Market Data") {
                    HStack {
                        Text("Current Price")
                        Spacer()
                        Text("$150.00")
                    }
                    
                    HStack {
                        Text("Bid")
                        Spacer()
                        Text("$149.95")
                    }
                    
                    HStack {
                        Text("Ask")
                        Spacer()
                        Text("$150.05")
                    }
                }
                
                Section("Order Preview") {
                    HStack {
                        Text("Estimated Cost")
                        Spacer()
                        Text("$15,000.00")
                    }
                    
                    Button(action: submitOrder) {
                        Text("Submit Order")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .navigationTitle("Trading")
            .padding()
        }
    }
    
    private func submitOrder() {
        // Implement order submission logic
    }
}

struct TradingView_Previews: PreviewProvider {
    static var previews: some View {
        TradingView()
            .environmentObject(AppViewModel())
    }
}
