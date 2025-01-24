import Foundation
import Combine
import SwiftUI
import Charts

/// View model for handling real-time market data updates
@MainActor
final class RealTimeMarketViewModel: ObservableObject, WebSocketObserver {
    // MARK: - Published Properties
    
    @Published private(set) var lastTrades: [String: Double] = [:]
    @Published private(set) var lastQuotes: [String: (bid: Double, ask: Double)] = [:]
    @Published private(set) var portfolioValue: Double = 0.0
    @Published private(set) var tradeUpdates: [String] = []
    @Published private(set) var isConnected: Bool = false {
        didSet {
            if !isConnected {
                handleDisconnection()
            }
        }
    }
    
    // Historical data for charts
    @Published private(set) var candleStickData: [String: [StockBarData]] = [:]
    @Published private(set) var portfolioHistory: [PricePoint] = []
    @Published private(set) var isLoadingHistoricalData: Bool = false
    @Published private(set) var lastError: Error?
    
    // MARK: - Private Properties
    
    private let marketDataService: MarketDataService
    private var cancellables = Set<AnyCancellable>()
    private let webSocketService: WebSocketService
    private let serialQueue = DispatchQueue(label: "com.zennic.realTimeMarketViewModel")
    private let maxTradeUpdates = 50
    private let decoder = JSONDecoder()
    private var subscribedSymbols: Set<String> = []
    private var reconnectTask: Task<Void, Never>?
    private var portfolioUpdateTimer: Timer?
    private let maxReconnectAttempts = 5
    private var reconnectAttempts = 0
    private var portfolioUpdateTask: Task<Void, Never>?
    
    // MARK: - Initialization
    
    init(marketDataService: MarketDataService = MarketDataService.shared,
         webSocketService: WebSocketService = WebSocketService.shared) {
        self.marketDataService = marketDataService
        self.webSocketService = webSocketService
        setupDecoder()
        startPortfolioUpdates()
        webSocketService.addObserver(self)
    }
    
    deinit {
        portfolioUpdateTimer?.invalidate()
        portfolioUpdateTimer = nil
        portfolioUpdateTask?.cancel()
        reconnectTask?.cancel()
        webSocketService.removeObserver(self)
    }
    
    private func setupDecoder() {
        decoder.dateDecodingStrategy = .iso8601
    }
    
    private func startPortfolioUpdates() {
        portfolioUpdateTask?.cancel()
        portfolioUpdateTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds
                guard let self = self else { break }
                
                // Calculate portfolio value
                let totalValue = self.lastTrades.reduce(0.0) { total, trade in
                    return total + trade.value
                }
                
                self.portfolioValue = totalValue
                self.portfolioHistory.append(PricePoint(date: Date(), price: totalValue))
                
                // Keep only last 24 hours of history
                let oneDayAgo = Date().addingTimeInterval(-24 * 60 * 60)
                self.portfolioHistory.removeAll { $0.date < oneDayAgo }
            }
        }
    }
    
    // MARK: - Public Methods
    
    func subscribeToSymbols(_ symbols: [String]) {
        guard !symbols.isEmpty else { return }
        
        Task { @MainActor in
            let newSymbols = Set(symbols).subtracting(subscribedSymbols)
            guard !newSymbols.isEmpty else { return }
            
            subscribedSymbols.formUnion(newSymbols)
            webSocketService.subscribeToSymbols(Array(newSymbols))
            await loadHistoricalData(for: Array(newSymbols))
        }
    }
    
    func unsubscribeFromSymbols(_ symbols: [String]) {
        guard !symbols.isEmpty else { return }
        
        Task { @MainActor in
            let existingSymbols = Set(symbols).intersection(subscribedSymbols)
            guard !existingSymbols.isEmpty else { return }
            
            subscribedSymbols.subtract(existingSymbols)
            webSocketService.unsubscribeFromSymbols(Array(existingSymbols))
            
            symbols.forEach { symbol in
                lastTrades.removeValue(forKey: symbol)
                lastQuotes.removeValue(forKey: symbol)
                candleStickData.removeValue(forKey: symbol)
            }
        }
    }
    
    /// Loads historical data for specified symbols
    /// - Parameter symbols: Array of stock symbols
    func loadHistoricalData(for symbols: [String]) async {
        guard !symbols.isEmpty else { return }
        
        isLoadingHistoricalData = true
        defer { isLoadingHistoricalData = false }
        
        do {
            try await withThrowingTaskGroup(of: (String, [StockBarData]).self) { group in
                for symbol in symbols {
                    group.addTask { [marketDataService] in
                        let now = Date()
                        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: now)!
                        let data = try await marketDataService.getHistoricalData(
                            symbol: symbol,
                            timeframe: "1Day",
                            start: thirtyDaysAgo,
                            end: now
                        )
                        return (symbol, data)
                    }
                }
                
                for try await (symbol, data) in group {
                    self.candleStickData[symbol] = data
                }
            }
        } catch {
            print("Error loading historical data: \(error)")
            self.lastError = error
        }
    }
    
    // MARK: - WebSocketObserver Methods
    
    nonisolated func didReceiveMessage(_ data: Data, type: WebSocketMessageType) {
        do {
            let message = try decoder.decode(WebSocketMessage.self, from: data)
            
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                switch message.data {
                case .trade(let tradeMessage):
                    self.lastTrades[tradeMessage.symbol] = tradeMessage.price
                case .quote(let quoteMessage):
                    self.lastQuotes[quoteMessage.symbol] = (bid: quoteMessage.bidPrice, ask: quoteMessage.askPrice)
                case .tradeUpdate(let update):
                    let updateText = "\(update.event.capitalized): \(update.symbol)"
                    self.tradeUpdates.insert(updateText, at: 0)
                    if self.tradeUpdates.count > self.maxTradeUpdates {
                        self.tradeUpdates.removeLast()
                    }
                case .news(let news):
                    print("Received news update: \(news.headline)")
                }
            }
        } catch {
            Task { @MainActor [weak self] in
                print("Error decoding WebSocket message: \(error)")
                self?.lastError = error
            }
        }
    }
    
    nonisolated func didConnect() {
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            self.isConnected = true
            self.lastError = nil
            self.reconnectAttempts = 0
            
            // Resubscribe to symbols
            let symbols = Array(self.subscribedSymbols)
            if !symbols.isEmpty {
                self.webSocketService.subscribeToSymbols(symbols)
            }
        }
    }
    
    nonisolated func didDisconnect(error: Error?) {
        Task { @MainActor [weak self] in
            self?.isConnected = false
            self?.lastError = error
            
            if let error = error {
                print("RealTimeMarketViewModel disconnected with error: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Private Methods
    
    @MainActor
    private func handleDisconnection() {
        Task { [weak self] in
            guard let self = self else { return }
            await self.clearData()
            self.reconnectIfNeeded()
        }
    }
    
    @MainActor
    private func clearData() async {
        lastTrades.removeAll()
        lastQuotes.removeAll()
        tradeUpdates.removeAll()
        candleStickData.removeAll()
        portfolioHistory.removeAll()
    }
    
    private func reconnectIfNeeded() {
        guard reconnectAttempts < maxReconnectAttempts else {
            lastError = NSError(domain: "RealTimeMarketViewModel",
                              code: -1,
                              userInfo: [NSLocalizedDescriptionKey: "Max reconnection attempts reached"])
            return
        }
        
        reconnectTask?.cancel()
        reconnectTask = Task { @MainActor [weak self] in
            guard let self = self else { return }
            
            // Exponential backoff
            let delay = TimeInterval(pow(2.0, Double(self.reconnectAttempts)))
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            
            self.reconnectAttempts += 1
            self.webSocketService.connect()
        }
    }
}
