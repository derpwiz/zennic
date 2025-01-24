import Foundation

/// Represents an order in the Alpaca trading system
struct Order: Codable {
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
    
    let symbol: String
    let assetClass: String?
    let qty: Double
    let filledQty: Double
    let type: OrderType
    let side: OrderSide
    let timeInForce: TimeInForce
    let limitPrice: Double?
    let stopPrice: Double?
    let status: OrderStatus
    
    private enum CodingKeys: String, CodingKey {
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

/// Represents different types of orders
enum OrderType: String, Codable, CaseIterable, Identifiable {
    case market
    case limit
    case stop
    case stopLimit = "stop_limit"
    case trailingStop = "trailing_stop"
    
    var id: String { rawValue }
    
    var description: String {
        switch self {
        case .market: return "Market"
        case .limit: return "Limit"
        case .stop: return "Stop"
        case .stopLimit: return "Stop Limit"
        case .trailingStop: return "Trailing Stop"
        }
    }
}

/// Represents the side of an order (buy or sell)
enum OrderSide: String, Codable, CaseIterable, Identifiable {
    case buy
    case sell
    
    var id: String { rawValue }
}

/// Represents different time-in-force options for orders
enum TimeInForce: String, Codable, CaseIterable, Identifiable {
    case day
    case gtc
    case opg
    case cls
    case ioc
    case fok
    
    var id: String { rawValue }
}

/// Represents different statuses an order can have
enum OrderStatus: String, Codable {
    case new
    case partialFill = "partially_filled"
    case filled
    case doneForDay = "done_for_day"
    case canceled
    case expired
    case replaced
    case pendingCancel = "pending_cancel"
    case pendingReplace = "pending_replace"
    case rejected
    case suspended
    case held
    case accepted
    case pendingNew = "pending_new"
    case acceptedForBidding = "accepted_for_bidding"
    case stopped
    case calculated
    case failed
}
