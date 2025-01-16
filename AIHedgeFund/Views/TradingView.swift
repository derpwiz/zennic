import SwiftUI
import Combine

struct TradingView: View {
    @EnvironmentObject private var appViewModel: AppViewModel
    @StateObject private var viewModel = TradingViewModel()
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Order Details")) {
                    TextField("Symbol", text: $viewModel.symbol)
                        .textCase(.uppercase)
                        .onChange(of: viewModel.symbol) { _ in
                            viewModel.fetchQuote()
                        }
                    Picker("Order Type", selection: $viewModel.orderType) {
                        ForEach(OrderType.allCases, id: \.self) { type in
                            Text(type.rawValue)
                        }
                    }
                    Picker("Action", selection: $viewModel.action) {
                        ForEach(TradeAction.allCases, id: \.self) { action in
                            Text(action.rawValue)
                        }
                    }
                    TextField("Quantity", text: $viewModel.quantity)
                    if viewModel.orderType == .limit {
                        TextField("Limit Price", text: $viewModel.limitPrice)
                    }
                }
                Section(header: Text("Market Data")) {
                    if viewModel.isLoading {
                        ProgressView()
                    } else {
                        HStack {
                            Text("Current Price")
                            Spacer()
                            Text(viewModel.currentPrice.map { String(format: "$%.2f", $0) } ?? "-")
                        }
                        HStack {
                            Text("Bid")
                            Spacer()
                            Text(viewModel.bid.map { String(format: "$%.2f", $0) } ?? "-")
                        }
                        HStack {
                            Text("Ask")
                            Spacer()
                            Text(viewModel.ask.map { String(format: "$%.2f", $0) } ?? "-")
                        }
                    }
                }
                Section(header: Text("Order Preview")) {
                    HStack {
                        Text("Estimated Cost")
                        Spacer()
                        Text(viewModel.estimatedCost.map { String(format: "$%.2f", $0) } ?? "-")
                    }
                    if let error = viewModel.error {
                        Text(error)
                            .foregroundColor(.red)
                    }
                    Button(action: { viewModel.submitOrder() }) {
                        Text("Submit Order")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!viewModel.canSubmitOrder)
                }
            }
            .navigationTitle("Trading")
            .padding()
            .alert("Order Submitted", isPresented: $viewModel.showOrderSuccess) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Your order has been submitted successfully.")
            }
        }
    }
}

@MainActor
final class TradingViewModel: ObservableObject {
    @Published var symbol = ""
    @Published var orderType: OrderType = .market
    @Published var action: TradeAction = .buy
    @Published var quantity = ""
    @Published var limitPrice = ""
    @Published private(set) var currentPrice: Double?
    @Published private(set) var bid: Double?
    @Published private(set) var ask: Double?
    @Published private(set) var isLoading = false
    @Published private(set) var error: String?
    @Published var showOrderSuccess = false
    private var cancellables = Set<AnyCancellable>()
    private var marketDataService: MarketDataService
    
    init(marketDataService: MarketDataService? = nil) {
        if let service = marketDataService {
            self.marketDataService = service
        } else {
            // Create a placeholder service, will be replaced in setup
            self.marketDataService = MarketDataService(apiKey: "")
        }
        Task {
            await setup()
        }
    }
    
    private func setup() async {
        if !marketDataService.hasValidAPIKey {
            await withCheckedContinuation { continuation in
                self.marketDataService = MarketDataService(apiKey: "YOUR_API_KEY")
                continuation.resume()
            }
        }
    }
    
    var estimatedCost: Double? {
        guard let quantity = Double(quantity) else { return nil }
        let price = orderType == .limit ? Double(limitPrice) ?? currentPrice : currentPrice
        guard let price = price else { return nil }
        return quantity * price
    }
    var canSubmitOrder: Bool {
        guard !symbol.isEmpty,
              let quantity = Double(quantity),
              quantity > 0 else {
            return false
        }
        if orderType == .limit {
            guard let limitPrice = Double(limitPrice),
                  limitPrice > 0 else {
                return false
            }
        }
        return currentPrice != nil && error == nil
    }
    func fetchQuote() {
        guard !symbol.isEmpty else {
            currentPrice = nil
            bid = nil
            ask = nil
            return
        }
        isLoading = true
        error = nil
        marketDataService.fetchStockPrice(symbol: symbol)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.error = error.localizedDescription
                }
            } receiveValue: { [weak self] price in
                self?.currentPrice = price
                // Simulate bid/ask spread
                self?.bid = price * 0.999
                self?.ask = price * 1.001
            }
            .store(in: &cancellables)
    }
    func submitOrder() {
        guard canSubmitOrder else { return }
        // Simulate order submission
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.showOrderSuccess = true
            self?.resetForm()
        }
    }
    private func resetForm() {
        symbol = ""
        quantity = ""
        limitPrice = ""
        orderType = .market
        action = .buy
        currentPrice = nil
        bid = nil
        ask = nil
    }
}

enum OrderType: String, CaseIterable {
    case market = "Market"
    case limit = "Limit"
}

enum TradeAction: String, CaseIterable {
    case buy = "Buy"
    case sell = "Sell"
}

struct TradingView_Previews: PreviewProvider {
    static var previews: some View {
        TradingView()
            .environmentObject(AppViewModel())
    }
}
