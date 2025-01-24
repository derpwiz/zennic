import SwiftUI
import Combine
import os
import Charts

@MainActor
final class DashboardViewModel: ObservableObject, WebSocketObserver {
    @Published var selectedSymbol: String?
    @Published var barData: [StockBarData] = []
    @Published var isLoading = false
    @Published var error: Error?
    @Published var lastTrades: [String: Double] = [:]
    @Published var lastQuotes: [String: (bid: Double, ask: Double)] = [:]
    @Published var isConnected = false
    
    private let portfolioService: PortfolioService
    private let alpacaService: AlpacaService
    private let webSocketService: WebSocketService
    private var cancellables = Set<AnyCancellable>()
    private let logger = Logger(subsystem: "com.zennic.app", category: "DashboardViewModel")
    
    var holdings: [PortfolioHolding] {
        portfolioService.holdings
    }
    
    init(apiKey: String = ProcessInfo.processInfo.environment["ALPACA_API_KEY"] ?? "",
         apiSecret: String = ProcessInfo.processInfo.environment["ALPACA_API_SECRET"] ?? "") {
        self.portfolioService = PortfolioService()
        self.alpacaService = .shared
        self.webSocketService = WebSocketService(apiKey: apiKey, apiSecret: apiSecret)
        logger.info("DashboardViewModel initialized")
        
        webSocketService.addObserver(self)
        
        Task {
            await loadData()
        }
        
        // Subscribe to holdings updates to trigger UI refresh when holdings change
        portfolioService.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
    
    func selectSymbol(_ symbol: String) {
        logger.info("Symbol selected: \(symbol)")
        selectedSymbol = symbol
        Task {
            await loadSelectedSymbolData(symbol: symbol)
        }
        
        // Subscribe to real-time updates for the selected symbol
        webSocketService.subscribeToSymbols([symbol])
    }
    
    private func loadSelectedSymbolData(symbol: String) async {
        logger.info("Loading data for symbol: \(symbol)")
        isLoading = true
        error = nil
        
        do {
            let bars = try await alpacaService.fetchBarData(
                symbol: symbol,
                timeframe: "1Day",
                limit: 30
            )
            barData = bars
        } catch {
            logger.error("Error loading data: \(error.localizedDescription)")
            self.error = error
        }
        
        isLoading = false
    }
    
    private func loadData() async {
        logger.info("Loading dashboard data")
        isLoading = true
        error = nil
        
        // Load initial data for all holdings
        for holding in holdings {
            await loadSelectedSymbolData(symbol: holding.symbol)
            // Subscribe to real-time updates for each holding
            webSocketService.subscribeToSymbols([holding.symbol])
        }
        
        isLoading = false
    }
    
    // MARK: - WebSocketObserver Methods
    
    nonisolated func didReceiveMessage(_ data: Data, type: WebSocketMessageType) {
        do {
            let message = try JSONDecoder().decode(WebSocketMessage.self, from: data)
            Task { @MainActor in
                switch message.data {
                case .trade(let tradeMessage):
                    await handleTrade(data, symbol: tradeMessage.symbol)
                case .quote(let quoteMessage):
                    await handleQuote(data, symbol: quoteMessage.symbol)
                case .tradeUpdate:
                    // Handle trade updates if needed
                    break
                case .news:
                    // Handle news updates if needed
                    break
                }
            }
        } catch {
            logger.error("Failed to decode WebSocket message: \(error.localizedDescription)")
        }
    }
    
    nonisolated func didConnect() {
        Task { @MainActor in
            isConnected = true
            logger.info("WebSocket connected")
        }
    }
    
    nonisolated func didDisconnect(error: Error?) {
        Task { @MainActor in
            isConnected = false
            if let error = error {
                logger.error("WebSocket disconnected with error: \(error.localizedDescription)")
            } else {
                logger.info("WebSocket disconnected")
            }
        }
    }
    
    private func handleTrade(_ data: Data, symbol: String) async {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let trade = json["data"] as? [String: Any],
              let price = trade["p"] as? Double else {
            logger.error("Failed to parse trade data")
            return
        }
        
        lastTrades[symbol] = price
    }
    
    private func handleQuote(_ data: Data, symbol: String) async {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let quote = json["data"] as? [String: Any],
              let bidPrice = quote["bp"] as? Double,
              let askPrice = quote["ap"] as? Double else {
            logger.error("Failed to parse quote data")
            return
        }
        
        lastQuotes[symbol] = (bid: bidPrice, ask: askPrice)
    }
    
    deinit {
        webSocketService.disconnect()
    }
}
