import SwiftUI
import Combine

struct TradingView: View {
    @EnvironmentObject private var appViewModel: AppViewModel
    @StateObject private var viewModel: TradingViewModel
    
    init() {
        let vm = TradingViewModel(
            appViewModel: nil,
            marketDataService: MarketDataService(
                apiKey: UserDefaults.standard.string(forKey: "alpacaApiKey") ?? "",
                apiSecret: UserDefaults.standard.string(forKey: "alpacaApiSecret") ?? ""
            )
        )
        _viewModel = StateObject(wrappedValue: vm)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                VStack {
                    Text("Order Details")
                        .font(.headline)
                    
                    TextField("Symbol", text: $viewModel.symbol)
                        .textCase(.uppercase)
                    
                    Picker("Order Type", selection: $viewModel.orderType) {
                        ForEach(OrderType.allCases, id: \.self) { type in
                            Text(type.rawValue.capitalized)
                        }
                    }
                    
                    Picker("Action", selection: $viewModel.action) {
                        ForEach(OrderSide.allCases, id: \.self) { side in
                            Text(side.rawValue.capitalized)
                        }
                    }
                    
                    TextField("Quantity", text: $viewModel.quantity)
                    
                    if viewModel.orderType == .limit {
                        TextField("Limit Price", text: $viewModel.limitPrice)
                    }
                }
                .padding()
                
                VStack {
                    if viewModel.isLoading {
                        ProgressView()
                    } else {
                        Button(action: {
                            Task {
                                await viewModel.submitOrder()
                            }
                        }) {
                            Text("Submit Order")
                                .frame(maxWidth: .infinity)
                        }
                        .disabled(viewModel.symbol.isEmpty || viewModel.quantity.isEmpty || 
                                (viewModel.orderType == .limit && viewModel.limitPrice.isEmpty))
                    }
                }
                .padding()
                
                if let error = viewModel.error {
                    VStack {
                        Text("Error")
                            .font(.headline)
                        Text(error)
                            .foregroundColor(.red)
                    }
                    .padding()
                }
                
                if let quote = viewModel.currentQuote {
                    VStack {
                        Text("Current Quote")
                            .font(.headline)
                        
                        HStack {
                            Text("Ask:")
                            Spacer()
                            Text(String(format: "%.2f", quote.ask ?? 0))
                        }
                        
                        HStack {
                            Text("Bid:")
                            Spacer()
                            Text(String(format: "%.2f", quote.bid ?? 0))
                        }
                    }
                    .padding()
                }
                
                if !viewModel.positions.isEmpty {
                    VStack {
                        Text("Positions")
                            .font(.headline)
                        
                        ForEach(viewModel.positions) { position in
                            HStack {
                                Text(position.symbol)
                                Spacer()
                                Text(String(format: "%.2f", position.shares))
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Trading")
            .alert("Order Status", isPresented: $viewModel.showOrderAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.orderAlertMessage)
            }
            .task {
                await viewModel.loadPositions()
            }
            .onAppear {
                // Update the MarketDataService with the latest API keys
                let apiKey = UserDefaults.standard.string(forKey: "alpacaApiKey") ?? ""
                let apiSecret = UserDefaults.standard.string(forKey: "alpacaApiSecret") ?? ""
                viewModel.updateMarketDataService(apiKey: apiKey, apiSecret: apiSecret)
            }
        }
    }
}

@MainActor
final class TradingViewModel: ObservableObject {
    @Published var symbol = ""
    @Published var orderType: OrderType = .market
    @Published var action: OrderSide = .buy
    @Published var quantity = ""
    @Published var limitPrice = ""
    @Published private(set) var currentQuote: AlpacaQuote?
    @Published private(set) var positions: [PortfolioHolding] = []
    @Published private(set) var isLoading = false
    @Published private(set) var error: String?
    @Published var showOrderAlert = false
    @Published private(set) var orderAlertMessage = ""
    
    private var cancellables = Set<AnyCancellable>()
    private var marketDataService: MarketDataService
    private weak var appViewModel: AppViewModel?
    
    init(appViewModel: AppViewModel?, marketDataService: MarketDataService) {
        self.appViewModel = appViewModel
        self.marketDataService = marketDataService
        setupBindings()
    }
    
    func updateMarketDataService(apiKey: String, apiSecret: String) {
        marketDataService = MarketDataService(apiKey: apiKey, apiSecret: apiSecret)
        setupBindings()
    }
    
    private func setupBindings() {
        $symbol
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .sink { [weak self] symbol in
                guard !symbol.isEmpty else {
                    self?.currentQuote = nil
                    return
                }
                self?.fetchQuote()
            }
            .store(in: &cancellables)
    }
    
    private func fetchQuote() {
        marketDataService.getQuote(for: symbol)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.error = error.localizedDescription
                }
            } receiveValue: { [weak self] quote in
                self?.currentQuote = quote
                self?.error = nil
            }
            .store(in: &cancellables)
    }
    
    public func loadPositions() async {
        isLoading = true
        error = nil
        
        do {
            let alpacaPositions = try await marketDataService.getPositions()
            positions = try alpacaPositions.compactMap { position in
                guard let shares = Double(position.qty),
                      let purchasePrice = Double(position.costBasis) else {
                    print("Error converting numeric values for position \(position.symbol)")
                    return nil
                }
                
                do {
                    return try PortfolioHolding(
                        symbol: position.symbol,
                        shares: shares,
                        purchasePrice: purchasePrice,
                        purchaseDate: Date()
                    )
                } catch {
                    print("Error creating PortfolioHolding for \(position.symbol): \(error)")
                    return nil
                }
            }
        } catch {
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func submitOrder() async {
        guard canSubmitOrder,
              let qty = Double(quantity) else { return }
        
        let limitPriceValue = Double(limitPrice)
        isLoading = true
        error = nil
        
        do {
            let order = try await marketDataService.placeOrder(
                symbol: symbol,
                qty: qty,
                side: action,
                type: orderType,
                timeInForce: .day,
                limitPrice: limitPriceValue
            )
            
            orderAlertMessage = "Order placed successfully: \(order.id)"
            showOrderAlert = true
            await loadPositions()
        } catch {
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }
    
    private var canSubmitOrder: Bool {
        !symbol.isEmpty && !quantity.isEmpty && 
        (orderType != .limit || !limitPrice.isEmpty)
    }
}

// Make OrderType conform to CaseIterable
extension OrderType: CaseIterable {
    static var allCases: [OrderType] = [.market, .limit]
}

// Make OrderSide conform to CaseIterable
extension OrderSide: CaseIterable {
    static var allCases: [OrderSide] = [.buy, .sell]
}

struct TradingView_Previews: PreviewProvider {
    static var previews: some View {
        TradingView()
            .environmentObject(AppViewModel())
    }
}
