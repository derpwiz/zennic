import Foundation

// MARK: - WebSocket Messages

/// Represents the type of WebSocket message
enum WebSocketMessageType {
    case tradeUpdate
    case trade
    case quote
    case news
}

/// Protocol for handling WebSocket messages
protocol WebSocketMessageDelegate: AnyObject {
    func didReceiveMessage(_ data: Data, type: WebSocketMessageType)
}

/// Protocol for handling WebSocket connection events
protocol WebSocketObserver: WebSocketMessageDelegate {
    func didConnect()
    func didDisconnect(error: Error?)
}

/// Default implementations for WebSocketObserver
extension WebSocketObserver {
    func didConnect() {}
    func didDisconnect(error: Error?) {}
}

/// Subscription types for WebSocket
enum WebSocketSubscriptionType: String {
    case trades = "trades"
    case quotes = "quotes"
    case bars = "bars"
    case dailyBars = "dailyBars"
    case statuses = "statuses"
    case lulds = "lulds"
    case tradeUpdates = "trade_updates"
}

/// Represents a WebSocket subscription request
struct WebSocketSubscription: Codable {
    let action: String
    let trades: [String]?
    let quotes: [String]?
    let bars: [String]?
    let dailyBars: [String]?
    let statuses: [String]?
    let lulds: [String]?
    let tradeUpdates: Bool?
    
    enum CodingKeys: String, CodingKey {
        case action
        case trades
        case quotes
        case bars
        case dailyBars = "dailyBars"
        case statuses
        case lulds
        case tradeUpdates = "trade_updates"
    }
}

/// Represents a WebSocket message
struct WebSocketMessage: Codable {
    let stream: String
    let data: WebSocketMessageData
    let timestamp: Date?
}

/// Represents different types of data that can be received from the WebSocket
enum WebSocketMessageData: Codable {
    case tradeUpdate(TradeUpdate)
    case quote(QuoteMessage)
    case trade(TradeMessage)
    case news(NewsItem)
    
    private enum CodingKeys: String, CodingKey {
        case type
        case data
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        
        switch type {
        case "trade_update":
            let data = try container.decode(TradeUpdate.self, forKey: .data)
            self = .tradeUpdate(data)
        case "quote":
            let data = try container.decode(QuoteMessage.self, forKey: .data)
            self = .quote(data)
        case "trade":
            let data = try container.decode(TradeMessage.self, forKey: .data)
            self = .trade(data)
        case "news":
            let data = try container.decode(NewsItem.self, forKey: .data)
            self = .news(data)
        default:
            throw DecodingError.dataCorruptedError(
                forKey: .type,
                in: container,
                debugDescription: "Unknown message type: \(type)"
            )
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case .tradeUpdate(let data):
            try container.encode("trade_update", forKey: .type)
            try container.encode(data, forKey: .data)
        case .quote(let data):
            try container.encode("quote", forKey: .type)
            try container.encode(data, forKey: .data)
        case .trade(let data):
            try container.encode("trade", forKey: .type)
            try container.encode(data, forKey: .data)
        case .news(let data):
            try container.encode("news", forKey: .type)
            try container.encode(data, forKey: .data)
        }
    }
}

/// Represents a trade update event
struct TradeUpdate: Codable {
    let event: String
    let price: Double
    let qty: Int
    let timestamp: Date
    let position_qty: Int
    let order_id: String
    let order_status: String
    let symbol: String
}

/// Represents a news item
struct NewsItem: Codable {
    let id: Int
    let headline: String
    let summary: String
    let author: String
    let created_at: Date
    let updated_at: Date
    let url: String
    let symbols: [String]
}

/// Represents a quote message
struct QuoteMessage: Codable {
    let symbol: String
    let bidPrice: Double
    let bidSize: Int
    let askPrice: Double
    let askSize: Int
    let timestamp: Date
    
    enum CodingKeys: String, CodingKey {
        case symbol = "S"
        case bidPrice = "bp"
        case bidSize = "bs"
        case askPrice = "ap"
        case askSize = "as"
        case timestamp = "t"
    }
}

/// Represents a trade message
struct TradeMessage: Codable {
    let symbol: String
    let price: Double
    let size: Int
    let timestamp: Date
    let tradeId: String
    let exchange: String
    
    enum CodingKeys: String, CodingKey {
        case symbol = "S"
        case price = "p"
        case size = "s"
        case timestamp = "t"
        case tradeId = "i"
        case exchange = "x"
    }
}

/// Represents a trade update message
struct TradeUpdateMessage: Codable {
    let event: String
    let price: Double?
    let timestamp: Date
    let position: PositionDelta?
    let order: OrderUpdate?
    
    enum CodingKeys: String, CodingKey {
        case event
        case price
        case timestamp
        case position
        case order
    }
}

/// Represents a position delta
struct PositionDelta: Codable {
    let assetId: String
    let symbol: String
    let qty: String
    let side: String
    
    enum CodingKeys: String, CodingKey {
        case assetId = "asset_id"
        case symbol
        case qty
        case side
    }
}

/// Represents an order update
struct OrderUpdate: Codable {
    let id: String
    let clientOrderId: String?
    let symbol: String
    let status: String
    let filledQty: String
    let filledAvgPrice: Double?
    
    enum CodingKeys: String, CodingKey {
        case id
        case clientOrderId = "client_order_id"
        case symbol
        case status
        case filledQty = "filled_qty"
        case filledAvgPrice = "filled_avg_price"
    }
}
