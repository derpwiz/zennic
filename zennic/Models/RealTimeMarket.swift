import Foundation
import Combine

/// Manages real-time market data using WebSocket connection
final class RealTimeMarket: ObservableObject, WebSocketObserver {
    // MARK: - Published Properties
    
    @Published private(set) var trades: [String: TradeMessage] = [:] {
        didSet {
            cleanupOldData()
        }
    }
    @Published private(set) var quotes: [String: QuoteMessage] = [:] {
        didSet {
            cleanupOldData()
        }
    }
    @Published private(set) var isConnected: Bool = false {
        didSet {
            if !isConnected {
                clearData()
            }
        }
    }
    @Published private(set) var lastError: Error?
    
    // MARK: - Computed Properties
    
    var lastTrades: [String: Double] {
        queue.sync {
            trades.mapValues { $0.price }
        }
    }
    
    // MARK: - Private Properties
    
    private var subscriptions = Set<AnyCancellable>()
    private let decoder = JSONDecoder()
    private let webSocketService: WebSocketService
    private let queue = DispatchQueue(label: "com.zennic.realTimeMarket", attributes: .concurrent)
    private let dataRetentionInterval: TimeInterval = 300 // 5 minutes
    private var lastCleanup = Date()
    private let cleanupInterval: TimeInterval = 60 // 1 minute
    
    // MARK: - Initialization
    
    init(webSocketService: WebSocketService = WebSocketService.shared) {
        self.webSocketService = webSocketService
        setupDecoder()
        webSocketService.addObserver(self)
    }
    
    deinit {
        webSocketService.removeObserver(self)
        clearData()
    }
    
    private func setupDecoder() {
        decoder.dateDecodingStrategy = .iso8601
    }
    
    // MARK: - Public Methods
    
    /// Gets the formatted quote string for a symbol
    /// - Parameter symbol: The stock symbol
    /// - Returns: A formatted string with bid and ask prices
    func getQuote(for symbol: String) -> String {
        queue.sync {
            guard let quote = quotes[symbol] else {
                return "No quote available"
            }
            return String(format: "Bid: $%.2f x %d  Ask: $%.2f x %d",
                         quote.bidPrice, quote.bidSize,
                         quote.askPrice, quote.askSize)
        }
    }
    
    /// Connects to the WebSocket service
    func connect() {
        webSocketService.connect()
    }
    
    /// Disconnects from the WebSocket service
    func disconnect() {
        webSocketService.disconnect()
    }
    
    /// Subscribes to real-time updates for specified symbols
    /// - Parameter symbols: Array of stock symbols to subscribe to
    func subscribe(to symbols: [String]) {
        guard !symbols.isEmpty else { return }
        webSocketService.subscribeToSymbols(symbols)
    }
    
    /// Unsubscribes from real-time updates for specified symbols
    /// - Parameter symbols: Array of stock symbols to unsubscribe from
    func unsubscribe(from symbols: [String]) {
        guard !symbols.isEmpty else { return }
        webSocketService.unsubscribeFromSymbols(symbols)
        
        // Remove unsubscribed symbols from local cache
        queue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            symbols.forEach { symbol in
                self.trades.removeValue(forKey: symbol)
                self.quotes.removeValue(forKey: symbol)
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func clearData() {
        queue.async(flags: .barrier) { [weak self] in
            self?.trades.removeAll()
            self?.quotes.removeAll()
        }
    }
    
    private func cleanupOldData() {
        let now = Date()
        guard now.timeIntervalSince(lastCleanup) >= cleanupInterval else { return }
        
        queue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            
            let cutoffDate = now.addingTimeInterval(-self.dataRetentionInterval)
            
            // Remove old trades
            self.trades = self.trades.filter { _, trade in
                trade.timestamp > cutoffDate
            }
            
            // Remove old quotes
            self.quotes = self.quotes.filter { _, quote in
                quote.timestamp > cutoffDate
            }
            
            self.lastCleanup = now
        }
    }
    
    // MARK: - WebSocketObserver Methods
    
    func didConnect() {
        DispatchQueue.main.async { [weak self] in
            self?.isConnected = true
            self?.lastError = nil
        }
    }
    
    func didDisconnect(error: Error?) {
        DispatchQueue.main.async { [weak self] in
            self?.isConnected = false
            self?.lastError = error
            
            if let error = error {
                print("RealTimeMarket disconnected with error: \(error.localizedDescription)")
            }
        }
    }
    
    func didReceiveMessage(_ data: Data, type: WebSocketMessageType) {
        do {
            let message = try decoder.decode(WebSocketMessage.self, from: data)
            
            queue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }
                
                switch message.data {
                case .trade(let trade):
                    self.trades[trade.symbol] = trade
                case .quote(let quote):
                    self.quotes[quote.symbol] = quote
                case .tradeUpdate(let update):
                    print("Received trade update: \(update)")
                case .news(let news):
                    print("Received news: \(news.headline)")
                }
            }
        } catch {
            print("Error decoding market data: \(error)")
            DispatchQueue.main.async { [weak self] in
                self?.lastError = error
            }
        }
    }
}
