import SwiftUI

struct HoldingDetailView: View {
    let holding: PortfolioHolding
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section("Position Details") {
                    LabeledContent("Symbol", value: holding.symbol)
                    LabeledContent("Quantity", value: String(format: "%.2f", holding.quantity))
                    LabeledContent("Average Price", value: String(format: "$%.2f", holding.averagePrice))
                    LabeledContent("Market Value", value: String(format: "$%.2f", holding.marketValue))
                }
                
                Section("Performance") {
                    LabeledContent("Unrealized P/L", value: String(format: "$%.2f", holding.unrealizedPL))
                    LabeledContent("Today's Change", value: String(format: "%.2f%%", holding.changeToday * 100))
                }
                
                Section("Asset Information") {
                    LabeledContent("Asset Class", value: holding.assetClass)
                    LabeledContent("Asset ID", value: holding.assetId)
                }
            }
            .navigationTitle("Position Details")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    HoldingDetailView(holding: PortfolioHolding(
        symbol: "AAPL",
        quantity: 100,
        averagePrice: 150.0,
        marketValue: 16000.0,
        unrealizedPL: 1000.0,
        currentPrice: 160.0,
        lastDayPrice: 155.0,
        changeToday: 0.0323,
        assetId: "b0b6dd9d-8b9b-48a9-ba46-b9d54906e415",
        assetClass: "us_equity"
    ))
}
