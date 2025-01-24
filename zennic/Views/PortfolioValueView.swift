import SwiftUI

struct PortfolioValueView: View {
    @ObservedObject var viewModel: RealTimeMarketViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Portfolio Value")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("$\(String(format: "%.2f", viewModel.portfolioValue))")
                .font(.system(size: 36, weight: .bold))
            
            Divider()
            
            Text("Recent Updates")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 4) {
                    ForEach(viewModel.tradeUpdates, id: \.self) { update in
                        Text(update)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .frame(maxHeight: 200)
        }
        .padding()
        .background(Color(.windowBackgroundColor))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

// Preview provider for SwiftUI canvas
struct PortfolioValueView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = RealTimeMarketViewModel()
        PortfolioValueView(viewModel: viewModel)
            .frame(width: 300)
            .padding()
    }
}
