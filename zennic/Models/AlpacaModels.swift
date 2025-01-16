import Foundation

struct AlpacaQuote: Codable {
    let symbol: String
    let ask: Double?
    let askSize: Int?
    let bid: Double?
    let bidSize: Int?
    let timestamp: String
    
    enum CodingKeys: String, CodingKey {
        case symbol, ask, askSize, bid, bidSize, timestamp
    }
}

struct AlpacaPosition: Codable {
    let assetId: String
    let symbol: String
    let qty: String
    let marketValue: String
    let currentPrice: String
    let costBasis: String
    let unrealizedPl: String
    let unrealizedPlPc: String
    
    enum CodingKeys: String, CodingKey {
        case assetId = "asset_id"
        case symbol
        case qty
        case marketValue = "market_value"
        case currentPrice = "current_price"
        case costBasis = "cost_basis"
        case unrealizedPl = "unrealized_pl"
        case unrealizedPlPc = "unrealized_plpc"
    }
}

struct AlpacaOrder: Codable {
    let id: String
    let clientOrderId: String
    let createdAt: String
    let updatedAt: String
    let submittedAt: String
    let filledAt: String?
    let expiredAt: String?
    let canceledAt: String?
    let failedAt: String?
    let replacedAt: String?
    let replacedBy: String?
    let replaces: String?
    let assetId: String
    let symbol: String
    let assetClass: String
    let qty: String
    let filledQty: String
    let type: String
    let side: String
    let timeInForce: String
    let limitPrice: String?
    let stopPrice: String?
    let status: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case clientOrderId = "client_order_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case submittedAt = "submitted_at"
        case filledAt = "filled_at"
        case expiredAt = "expired_at"
        case canceledAt = "canceled_at"
        case failedAt = "failed_at"
        case replacedAt = "replaced_at"
        case replacedBy = "replaced_by"
        case replaces
        case assetId = "asset_id"
        case symbol
        case assetClass = "asset_class"
        case qty
        case filledQty = "filled_qty"
        case type
        case side
        case timeInForce = "time_in_force"
        case limitPrice = "limit_price"
        case stopPrice = "stop_price"
        case status
    }
}

enum OrderSide: String {
    case buy
    case sell
}

enum OrderType: String {
    case market
    case limit
    case stop
    case stopLimit = "stop_limit"
}

enum TimeInForce: String {
    case day
    case gtc
    case ioc
    case fok
}
