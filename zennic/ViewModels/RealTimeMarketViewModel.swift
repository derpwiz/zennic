import Foundation
import Combine

/// View model for handling real-time market data updates
final class RealTimeMarketViewModel: ObservableObject {
    @Published var lastTrades: [String: Double] = [:]
    @Published var lastQuotes: [String: (bid: Double, ask: Double)] = [:]
    @Published var portfolioValue: Double = 0.0
    @Published var tradeUpdates: [String] = []
    @Published var isConnected: Bool = false
    
    // Historical data for charts
    @Published var candleStickData: [String: [CandleStickData]] = [:]
    @Published var portfolioHistory: [PricePoint] = []
    @Published var isLoadingHistoricalData: Bool = false
    
    private var webSocketService: WebSocketService?
    private let marketDataService: MarketDataService
    private var cancellables = Set<AnyCancellable>()
    
    init(apiKey: String, apiSecret: String) {
        self.marketDataService = MarketDataService(apiKey: apiKey, apiSecret: apiSecret)
        setupWebSocket(apiKey: apiKey, apiSecret: apiSecret)
    }
    
    // MARK: - WebSocket Methods
    
    func connect() {
        webSocketService?.connect()
    }
    
    func disconnect() {
        webSocketService?.disconnect()
    }
    
    func subscribeToSymbols(_ symbols: [String]) {
        webSocketService?.subscribeToSymbols(symbols)
        // Load historical data for newly subscribed symbols
        Task {
            await loadHistoricalData(for: symbols)
        }
    }
    
    func unsubscribeFromSymbols(_ symbols: [String]) {
        webSocketService?.unsubscribeFromSymbols(symbols)
    }
    
    // MARK: - Historical Data Methods
    
    /// Loads historical data for specified symbols
    /// - Parameter symbols: Array of stock symbols
    @MainActor
    func loadHistoricalData(for symbols: [String]) async {
        guard !symbols.isEmpty else { return }
        
        isLoadingHistoricalData = true
        defer { isLoadingHistoricalData = false }
        
        do {
            // Get data for the last day with 1-minute bars
            let endDate = Date()
            let startDate = Calendar.current.date(byAdding: .day, value: -1, to: endDate)!
            
            for symbol in symbols {
                let bars = try await marketDataService.getHistoricalBars(
                    symbol: symbol,
                    timeframe: "1Min",
                    start: startDate,
                    end: endDate
                )
                candleStickData[symbol] = bars
            }
        } catch {
            print("Error loading historical data: \(error)")
        }
    }
    
    /// Loads portfolio performance history
    /// - Parameter period: Time period to load data for
    @MainActor
    func loadPortfolioHistory(for period: ChartTimePeriod) async {
        isLoadingHistoricalData = true
        defer { isLoadingHistoricalData = false }
        
        do {
            let endDate = Date()
            let startDate = Calendar.current.date(byAdding: .day, value: -period.days, to: endDate)!
            
            // Get historical data for all holdings
            let holdingsData = try await marketDataService.getHistoricalTrades(
                symbols: Array(lastTrades.keys),
                start: startDate,
                end: endDate
            )
            
            // Calculate portfolio value at each point
            var portfolioValues: [PricePoint] = []
            let timePoints = Set(holdingsData.values.flatMap { $0.map(\.date) }).sorted()
            
            for date in timePoints {
                var totalValue = 0.0
                for (symbol, prices) in holdingsData {
                    if let price = prices.first(where: { $0.date <= date })?.price {
                        totalValue += price * (lastTrades[symbol] ?? 0)
                    }
                }
                portfolioValues.append(PricePoint(date: date, price: totalValue))
            }
            
            self.portfolioHistory = portfolioValues
        } catch {
            print("Error loading portfolio history: \(error)")
        }
    }
    
    private func setupWebSocket(apiKey: String, apiSecret: String) {
        webSocketService = WebSocketService(apiKey: apiKey, apiSecret: apiSecret, delegate: self)
    }
}

// MARK: - WebSocket Delegate

extension RealTimeMarketViewModel: WebSocketDelegate {
    func didReceiveMessage(_ message: Data, type: WebSocketMessageType) {
        switch type {
        case .tradeUpdate:
            handleTradeUpdate(message)
        case .quote(let symbol):
            handleQuote(message, symbol: symbol)
        case .trade(let symbol):
            handleTrade(message, symbol: symbol)
        case .news:
            // Handle news updates if needed
            break
        }
    }
    
    func didConnect() {
        DispatchQueue.main.async {
            self.isConnected = true
        }
    }
    
    func didDisconnect(error: Error?) {
        DispatchQueue.main.async {
            self.isConnected = false
        }
    }
    
    private func handleTradeUpdate(_ data: Data) {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let event = json["data"] as? [String: Any],
              let eventType = event["event"] as? String else {
            return
        }
        
        DispatchQueue.main.async {
            self.tradeUpdates.insert(eventType, at: 0)
            if self.tradeUpdates.count > 50 {
                self.tradeUpdates.removeLast()
            }
            
            // Trigger portfolio history update when trades occur
            Task {
                await self.loadPortfolioHistory(for: .day)
            }
        }
    }
    
    private func handleQuote(_ data: Data, symbol: String) {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let quote = json["data"] as? [String: Any],
              let bidPrice = quote["bp"] as? Double,
              let askPrice = quote["ap"] as? Double else {
            return
        }
        
        DispatchQueue.main.async {
            self.lastQuotes[symbol] = (bid: bidPrice, ask: askPrice)
        }
    }
    
    private func handleTrade(_ data: Data, symbol: String) {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let trade = json["data"] as? [String: Any],
              let price = trade["p"] as? Double else {
            return
        }
        
        DispatchQueue.main.async {
            self.lastTrades[symbol] = price
            
            // Update candlestick data with the new trade
            if var bars = self.candleStickData[symbol],
               let lastBar = bars.last {
                let calendar = Calendar.current
                if calendar.isDate(lastBar.date, equalTo: Date(), toGranularity: .minute) {
                    // Update the last bar
                    bars[bars.count - 1] = CandleStickData(
                        date: lastBar.date,
                        open: lastBar.open,
                        high: max(lastBar.high, price),
                        low: min(lastBar.low, price),
                        close: price,
                        volume: lastBar.volume + 1
                    )
                } else {
                    // Add a new bar
                    bars.append(CandleStickData(
                        date: Date(),
                        open: price,
                        high: price,
                        low: price,
                        close: price,
                        volume: 1
                    ))
                }
                self.candleStickData[symbol] = bars
            }
        }
    }
}
