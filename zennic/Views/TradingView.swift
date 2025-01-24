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
                        ForEach(OrderType.allCases) { type in
                            Text(type.description)
                                .tag(type)
                        }
                    }
                    
                    Picker("Action", selection: $viewModel.action) {
                        ForEach(OrderSide.allCases) { side in
                            Text(side.rawValue.capitalized)
                                .tag(side)
                        }
                    }
                    
                    TextField("Quantity", text: $viewModel.quantity)
                        .onReceive(Just(viewModel.quantity)) { newValue in
                            let filtered = newValue.filter { "0123456789".contains($0) }
                            if filtered != newValue {
                                viewModel.quantity = filtered
                            }
                        }
                    
                    if viewModel.orderType == .limit {
                        TextField("Limit Price", text: $viewModel.limitPrice)
                            .onReceive(Just(viewModel.limitPrice)) { newValue in
                                let filtered = newValue.filter { "0123456789.".contains($0) }
                                if filtered != newValue {
                                    viewModel.limitPrice = filtered
                                }
                            }
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
                            Text(String(format: "%.2f", quote.askPrice))
                        }
                        
                        HStack {
                            Text("Bid:")
                            Spacer()
                            Text(String(format: "%.2f", quote.bidPrice))
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
                                Text(String(format: "%.2f", position.quantity))
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
                Task {
                    await self?.fetchQuote()
                }
            }
            .store(in: &cancellables)
    }
    
    private func fetchQuote() async {
        do {
            let quote = try await marketDataService.fetchQuote(symbol: symbol)
            await MainActor.run {
                self.currentQuote = quote
                self.error = nil
            }
        } catch {
            await MainActor.run {
                self.error = error.localizedDescription
            }
        }
    }
    
    public func loadPositions() async {
        await MainActor.run { isLoading = true }
        
        // For now, since we don't have a getPositions endpoint, we'll leave this empty
        // You would need to implement this in MarketDataService or use AlpacaService
        await MainActor.run {
            positions = []
            isLoading = false
        }
    }
    
    func submitOrder() async {
        guard canSubmitOrder,
              let _ = Double(quantity) else { return }
        
        let _ = Double(limitPrice) // Placeholder for future implementation
        await MainActor.run { isLoading = true }
        
        // For now, since we don't have a placeOrder endpoint, we'll just show a message
        // You would need to implement this in MarketDataService or use AlpacaService
        await MainActor.run {
            orderAlertMessage = "Order submission not implemented yet"
            showOrderAlert = true
            isLoading = false
        }
    }
    
    private var canSubmitOrder: Bool {
        !symbol.isEmpty && !quantity.isEmpty && 
        (orderType != .limit || !limitPrice.isEmpty)
    }
}

struct TradingView_Previews: PreviewProvider {
    static var previews: some View {
        TradingView()
            .environmentObject(AppViewModel())
    }
}
