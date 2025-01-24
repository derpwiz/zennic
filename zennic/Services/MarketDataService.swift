import Foundation
import Combine
import SwiftUI
import Charts

/// Service class responsible for interacting with market data APIs
final class MarketDataService {
    // MARK: - Properties
    
    static var shared = MarketDataService()
    
    private let session: URLSession
    private let baseURL: URL
    private let dateFormatter: ISO8601DateFormatter
    private let decoder: JSONDecoder
    private let queue = DispatchQueue(label: "com.zennic.marketdata", qos: .userInitiated)
    
    // MARK: - Initialization
    
    init(apiKey: String = ProcessInfo.processInfo.environment["ALPACA_API_KEY"] ?? "",
         apiSecret: String = ProcessInfo.processInfo.environment["ALPACA_API_SECRET"] ?? "",
         baseURL: URL = URL(string: "https://data.alpaca.markets/v2")!) {
        self.baseURL = baseURL
        
        // Configure URLSession
        let config = URLSessionConfiguration.default
        config.httpAdditionalHeaders = [
            "APCA-API-KEY-ID": apiKey,
            "APCA-API-SECRET-KEY": apiSecret
        ]
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 300
        self.session = URLSession(configuration: config)
        
        // Configure date formatter
        self.dateFormatter = ISO8601DateFormatter()
        
        // Configure decoder
        self.decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let timestamp = try container.decode(String.self)
            
            if let date = self.dateFormatter.date(from: timestamp) {
                return date
            }
            
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Invalid date format"
            )
        }
    }
    
    /// Updates the shared instance with new API credentials
    static func updateShared(apiKey: String, apiSecret: String) {
        shared = MarketDataService(apiKey: apiKey, apiSecret: apiSecret)
    }
    
    // MARK: - Public Methods
    
    /// Fetches historical bar data for a given symbol and timeframe
    /// - Parameters:
    ///   - symbol: The stock symbol to fetch data for
    ///   - timeframe: The timeframe for the bars (e.g., "1Day", "1Hour")
    ///   - limit: Maximum number of bars to return
    /// - Returns: An array of StockBarData
    func fetchBarData(symbol: String, timeframe: String, limit: Int = 100) async throws -> [StockBarData] {
        var components = URLComponents(url: baseURL.appendingPathComponent("stocks/\(symbol)/bars"), resolvingAgainstBaseURL: true)!
        components.queryItems = [
            URLQueryItem(name: "timeframe", value: timeframe),
            URLQueryItem(name: "limit", value: String(limit))
        ]
        
        guard let url = components.url else {
            throw APIError.invalidResponse
        }
        
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw APIError.httpError(statusCode: httpResponse.statusCode)
        }
        
        let barsResponse = try decoder.decode(BarsResponse.self, from: data)
        guard !barsResponse.bars.isEmpty else {
            throw APIError.serverError(message: "No data available for \(symbol)")
        }
        
        return barsResponse.bars
    }
    
    /// Fetches latest quote data for a given symbol
    /// - Parameter symbol: The stock symbol to fetch data for
    /// - Returns: The latest quote data
    func fetchQuote(symbol: String) async throws -> AlpacaQuote {
        let url = baseURL.appendingPathComponent("stocks/\(symbol)/quotes/latest")
        
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw APIError.httpError(statusCode: httpResponse.statusCode)
        }
        
        return try decoder.decode(AlpacaQuote.self, from: data)
    }
    
    /// Fetches latest trade data for a given symbol
    /// - Parameter symbol: The stock symbol to fetch data for
    /// - Returns: The latest trade data
    func fetchTrade(symbol: String) async throws -> AlpacaTrade {
        let url = baseURL.appendingPathComponent("stocks/\(symbol)/trades/latest")
        
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw APIError.httpError(statusCode: httpResponse.statusCode)
        }
        
        return try decoder.decode(AlpacaTrade.self, from: data)
    }
    
    /// Fetches historical price data between two dates
    /// - Parameters:
    ///   - symbol: The stock symbol to fetch data for
    ///   - timeframe: The timeframe for the bars
    ///   - start: Start date
    ///   - end: End date
    /// - Returns: An array of StockBarData
    func getHistoricalData(symbol: String, timeframe: String, start: Date, end: Date) async throws -> [StockBarData] {
        var components = URLComponents(url: baseURL.appendingPathComponent("stocks/\(symbol)/bars"), resolvingAgainstBaseURL: true)!
        components.queryItems = [
            URLQueryItem(name: "timeframe", value: timeframe),
            URLQueryItem(name: "start", value: dateFormatter.string(from: start)),
            URLQueryItem(name: "end", value: dateFormatter.string(from: end))
        ]
        
        guard let url = components.url else {
            throw APIError.invalidResponse
        }
        
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw APIError.httpError(statusCode: httpResponse.statusCode)
        }
        
        let barsResponse = try decoder.decode(BarsResponse.self, from: data)
        guard !barsResponse.bars.isEmpty else {
            throw APIError.serverError(message: "No historical data available for \(symbol)")
        }
        
        return barsResponse.bars
    }
    
    /// Fetches historical prices for multiple symbols
    /// - Parameters:
    ///   - symbols: Array of stock symbols
    ///   - timeframe: The timeframe for the bars
    ///   - start: Start date for historical data
    ///   - end: End date for historical data
    /// - Returns: Dictionary mapping symbols to their historical price data
    func getHistoricalPrices(symbols: [String], timeframe: String, start: Date, end: Date) async throws -> [String: [PricePoint]] {
        var result: [String: [PricePoint]] = [:]
        
        try await withThrowingTaskGroup(of: (String, [PricePoint]).self) { group in
            for symbol in symbols {
                group.addTask {
                    let bars = try await self.getHistoricalData(
                        symbol: symbol,
                        timeframe: timeframe,
                        start: start,
                        end: end
                    )
                    
                    let pricePoints = bars.map { bar in
                        PricePoint(date: bar.timestamp, price: bar.closePrice)
                    }
                    
                    return (symbol, pricePoints)
                }
            }
            
            for try await (symbol, prices) in group {
                result[symbol] = prices
            }
        }
        
        return result
    }
    
    /// Fetches historical portfolio prices between two dates
    /// - Parameters:
    ///   - holdings: Array of portfolio holdings
    ///   - timeframe: The timeframe for the bars
    ///   - start: Start date
    ///   - end: End date
    /// - Returns: Array of price points representing portfolio value over time
    func getHistoricalPrices(holdings: [PortfolioHolding], timeframe: String, start: Date, end: Date) async throws -> [PricePoint] {
        var pricePoints: [PricePoint] = []
        
        try await withThrowingTaskGroup(of: [StockBarData].self) { group in
            for holding in holdings {
                group.addTask {
                    return try await self.getHistoricalData(
                        symbol: holding.symbol,
                        timeframe: timeframe,
                        start: start,
                        end: end
                    )
                }
            }
            
            for try await bars in group {
                for bar in bars {
                    if let existingIndex = pricePoints.firstIndex(where: { $0.date == bar.timestamp }) {
                        let additionalValue = bar.closePrice * Double(holdings.first { $0.symbol == bar.symbol }?.quantity ?? 0)
                        let newValue = pricePoints[existingIndex].price + additionalValue
                        pricePoints[existingIndex] = PricePoint(date: bar.timestamp, price: newValue)
                    } else {
                        let value = bar.closePrice * Double(holdings.first { $0.symbol == bar.symbol }?.quantity ?? 0)
                        pricePoints.append(PricePoint(date: bar.timestamp, price: value))
                    }
                }
            }
        }
        
        return pricePoints.sorted { $0.date < $1.date }
    }
    
    /// Fetches historical bar data for a given symbol and timeframe
    /// - Parameters:
    ///   - symbol: The stock symbol to fetch data for
    ///   - timeframe: The timeframe for the bars
    /// - Returns: An array of StockBarData
    func fetchBars(symbol: String, timeframe: ChartTimePeriod) async throws -> [StockBarData] {
        return try await fetchBarData(symbol: symbol, timeframe: timeframe.timeframe)
    }
}
