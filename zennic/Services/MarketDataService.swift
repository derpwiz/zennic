import Foundation
import Combine

/// Represents possible errors that can occur when interacting with the market data API
enum MarketDataError: Error {
    /// The API response was not in the expected format
    case invalidResponse
    /// The price data received was invalid
    case invalidPrice
    /// The API credentials are invalid or expired
    case unauthorized
    /// A general API error occurred with a specific message
    case apiError(String)
}

/// Service responsible for fetching market data and executing trades through the Alpaca API.
/// This service handles all communication with Alpaca's paper trading environment.
final class MarketDataService {
    private let apiKey: String
    private let apiSecret: String
    private let session: URLSession
    private let baseURL = URL(string: "https://paper-api.alpaca.markets/v2")!
    
    /// Indicates whether the service has valid API credentials
    var hasValidCredentials: Bool {
        !apiKey.isEmpty && !apiSecret.isEmpty
    }
    
    /// Initializes the market data service with Alpaca API credentials
    /// - Parameters:
    ///   - apiKey: The Alpaca API key
    ///   - apiSecret: The Alpaca API secret
    init(apiKey: String, apiSecret: String) {
        self.apiKey = apiKey
        self.apiSecret = apiSecret
        
        let config = URLSessionConfiguration.default
        config.httpAdditionalHeaders = [
            "APCA-API-KEY-ID": apiKey,
            "APCA-API-SECRET-KEY": apiSecret
        ]
        self.session = URLSession(configuration: config)
    }
    
    /// Fetches the latest quote for a given stock symbol
    /// - Parameter symbol: The stock symbol to get the quote for
    /// - Returns: A publisher that emits the quote data or an error
    func getQuote(for symbol: String) -> AnyPublisher<AlpacaQuote, Error> {
        let url = baseURL.appendingPathComponent("quotes/\(symbol)/latest")
        
        return session.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: AlpacaQuote.self, decoder: JSONDecoder())
            .eraseToAnyPublisher()
    }
    
    /// Retrieves all current positions in the portfolio
    /// - Returns: An array of positions
    /// - Throws: An error if the request fails or the response is invalid
    func getPositions() async throws -> [AlpacaPosition] {
        let url = baseURL.appendingPathComponent("positions")
        let (data, _) = try await session.data(from: url)
        return try JSONDecoder().decode([AlpacaPosition].self, from: data)
    }
    
    /// Places an order for a given stock symbol
    /// - Parameters:
    ///   - symbol: The stock symbol to place the order for
    ///   - qty: The quantity of shares to buy or sell
    ///   - side: The side of the order (buy or sell)
    ///   - type: The type of order (market, limit, stop, or stop limit)
    ///   - timeInForce: The time in force for the order (day, gtc, opg, cls, ioc, or fok)
    ///   - limitPrice: The limit price for the order (optional)
    /// - Returns: The placed order
    /// - Throws: An error if the request fails or the response is invalid
    func placeOrder(
        symbol: String,
        qty: Double,
        side: OrderSide,
        type: OrderType,
        timeInForce: TimeInForce,
        limitPrice: Double? = nil
    ) async throws -> AlpacaOrder {
        let url = baseURL.appendingPathComponent("orders")
        
        var parameters: [String: Any] = [
            "symbol": symbol,
            "qty": String(format: "%.2f", qty),
            "side": side.rawValue,
            "type": type.rawValue,
            "time_in_force": timeInForce.rawValue
        ]
        
        if let limitPrice = limitPrice {
            parameters["limit_price"] = String(format: "%.2f", limitPrice)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: parameters)
        
        let (data, _) = try await session.data(for: request)
        return try JSONDecoder().decode(AlpacaOrder.self, from: data)
    }
    
    /// Fetches historical bar data for a symbol
    /// - Parameters:
    ///   - symbol: The stock symbol
    ///   - timeframe: Timeframe for each bar (1Min, 5Min, 15Min, 1H, 1D)
    ///   - start: Start date
    ///   - end: End date (optional, defaults to now)
    /// - Returns: Array of CandleStickData
    func getHistoricalBars(
        symbol: String,
        timeframe: String,
        start: Date,
        end: Date? = nil
    ) async throws -> [CandleStickData] {
        var components = URLComponents(url: baseURL.appendingPathComponent("bars"), resolvingAgainstBaseURL: true)!
        components.queryItems = [
            URLQueryItem(name: "symbols", value: symbol),
            URLQueryItem(name: "timeframe", value: timeframe),
            URLQueryItem(name: "start", value: formatDate(start)),
            URLQueryItem(name: "limit", value: "1000")
        ]
        
        if let end = end {
            components.queryItems?.append(URLQueryItem(name: "end", value: formatDate(end)))
        }
        
        guard let url = components.url else {
            throw MarketDataError.invalidResponse
        }
        
        let (data, _) = try await session.data(from: url)
        let response = try JSONDecoder().decode(BarsResponse.self, from: data)
        
        return response.bars.map { bar in
            CandleStickData(
                date: bar.timestamp,
                open: bar.openPrice,
                high: bar.highPrice,
                low: bar.lowPrice,
                close: bar.closePrice,
                volume: bar.volume
            )
        }
    }
    
    /// Fetches trade data for portfolio performance tracking
    /// - Parameters:
    ///   - symbols: Array of stock symbols
    ///   - start: Start date
    ///   - end: End date (optional, defaults to now)
    /// - Returns: Dictionary of symbol to array of PricePoint
    func getHistoricalTrades(
        symbols: [String],
        start: Date,
        end: Date? = nil
    ) async throws -> [String: [PricePoint]] {
        var result: [String: [PricePoint]] = [:]
        
        for symbol in symbols {
            let bars = try await getHistoricalBars(
                symbol: symbol,
                timeframe: "1Min",
                start: start,
                end: end
            )
            
            result[symbol] = bars.map { PricePoint(date: $0.date, price: $0.close) }
        }
        
        return result
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.string(from: date)
    }
}

// MARK: - Response Models

struct BarsResponse: Codable {
    let bars: [Bar]
    
    enum CodingKeys: String, CodingKey {
        case bars = "bars"
    }
}

struct Bar: Codable {
    let timestamp: Date
    let openPrice: Double
    let highPrice: Double
    let lowPrice: Double
    let closePrice: Double
    let volume: Double
    
    enum CodingKeys: String, CodingKey {
        case timestamp = "t"
        case openPrice = "o"
        case highPrice = "h"
        case lowPrice = "l"
        case closePrice = "c"
        case volume = "v"
    }
}

// Move these models to a separate file
struct AlpacaQuote: Codable {
    let ask: Double?
    let bid: Double?
    let askSize: Int?
    let bidSize: Int?
    let timestamp: Date?
}

struct AlpacaPosition: Codable {
    let symbol: String
    let qty: String
    let costBasis: String
    let marketValue: String
    let unrealizedPL: String
    let currentPrice: String
    let lastDayPrice: String
    let changeToday: String
    let assetId: String
    let assetClass: String
    
    enum CodingKeys: String, CodingKey {
        case symbol
        case qty
        case costBasis = "cost_basis"
        case marketValue = "market_value"
        case unrealizedPL = "unrealized_pl"
        case currentPrice = "current_price"
        case lastDayPrice = "lastday_price"
        case changeToday = "change_today"
        case assetId = "asset_id"
        case assetClass = "asset_class"
    }
}

struct AlpacaOrder: Codable {
    let id: String
    let clientOrderId: String?
    let createdAt: Date
    let updatedAt: Date?
    let submittedAt: Date?
    let filledAt: Date?
    let expiredAt: Date?
    let canceledAt: Date?
    let failedAt: Date?
    let replacedAt: Date?
    let replacedBy: String?
    let replaces: String?
    let assetId: String
    let symbol: String
    let assetClass: String
    let notional: Double?
    let qty: Double?
    let filledQty: Double?
    let type: String
    let side: String
    let timeInForce: String
    let limitPrice: Double?
    let stopPrice: Double?
    let status: String
}

enum OrderSide: String {
    case buy
    case sell
}

enum OrderType: String {
    case market
    case limit
    case stop
    case stopLimit
}

enum TimeInForce: String {
    case day = "day"
    case gtc = "gtc"
    case opg = "opg"
    case cls = "cls"
    case ioc = "ioc"
    case fok = "fok"
}
