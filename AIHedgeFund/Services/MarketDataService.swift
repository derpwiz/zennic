import Foundation
import Combine

enum MarketDataError: Error {
    case invalidResponse
    case invalidPrice
    case unauthorized
    case apiError(String)
}

class MarketDataService {
    private let apiKey: String
    private let apiSecret: String
    private let session: URLSession
    private let baseURL = URL(string: "https://paper-api.alpaca.markets/v2")!
    
    var hasValidCredentials: Bool {
        !apiKey.isEmpty && !apiSecret.isEmpty
    }
    
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
    
    func getQuote(for symbol: String) -> AnyPublisher<AlpacaQuote, Error> {
        let url = baseURL.appendingPathComponent("quotes/\(symbol)/latest")
        
        return session.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: AlpacaQuote.self, decoder: JSONDecoder())
            .eraseToAnyPublisher()
    }
    
    func getPositions() async throws -> [AlpacaPosition] {
        let url = baseURL.appendingPathComponent("positions")
        let (data, _) = try await session.data(from: url)
        return try JSONDecoder().decode([AlpacaPosition].self, from: data)
    }
    
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
}

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
