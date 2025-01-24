import Foundation

/// Represents an order placed on the Alpaca platform
struct AlpacaOrder: Codable {
    let id: String
    let clientOrderId: String
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
    let notional: String?
    let qty: String?
    let filledQty: String?
    let filledAvgPrice: String?
    let orderClass: String?
    let orderType: String
    let type: String
    let side: String
    let timeInForce: String
    let limitPrice: String?
    let stopPrice: String?
    let status: String
    let extendedHours: Bool
    let legs: [AlpacaOrder]?
    let trailPercent: String?
    let trailPrice: String?
    let hwm: String?
    
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
        case notional
        case qty
        case filledQty = "filled_qty"
        case filledAvgPrice = "filled_avg_price"
        case orderClass = "order_class"
        case orderType = "order_type"
        case type
        case side
        case timeInForce = "time_in_force"
        case limitPrice = "limit_price"
        case stopPrice = "stop_price"
        case status
        case extendedHours = "extended_hours"
        case legs
        case trailPercent = "trail_percent"
        case trailPrice = "trail_price"
        case hwm
    }
}

/// Represents Alpaca API keys
struct AlpacaKeys: Codable {
    let apiKey: String
    let apiSecret: String
    let isPaperTrading: Bool
    
    enum CodingKeys: String, CodingKey {
        case apiKey = "api_key"
        case apiSecret = "api_secret"
        case isPaperTrading = "is_paper_trading"
    }
}

/// Used for creating new Alpaca API keys
struct AlpacaKeysCreate: Codable {
    let apiKey: String
    let apiSecret: String
    let isPaperTrading: Bool
    
    enum CodingKeys: String, CodingKey {
        case apiKey = "api_key"
        case apiSecret = "api_secret"
        case isPaperTrading = "is_paper_trading"
    }
}

/// Represents an OAuth request to Alpaca
struct AlpacaOAuthRequest {
    let clientId: String
    let redirectUri: String
    let responseType: String
    let scope: String
}

/// Represents an OAuth response from Alpaca
struct AlpacaOAuthResponse: Codable {
    let accessToken: String
    let refreshToken: String
    let expiresIn: Int
    let scope: String
    let tokenType: String
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
        case scope
        case tokenType = "token_type"
    }
}

/// Represents an OAuth error response from Alpaca
struct AlpacaOAuthError: Codable {
    let error: String
    let errorDescription: String
    
    enum CodingKeys: String, CodingKey {
        case error
        case errorDescription = "error_description"
    }
}

/// Represents an error response
struct ErrorResponse: Codable {
    let reason: String
}

/// Represents a news item from Alpaca
struct AlpacaNews: Codable {
    let id: Int
    let headline: String
    let summary: String
    let author: String
    let timestamp: Date
    let url: String
    let symbols: [String]
    
    enum CodingKeys: String, CodingKey {
        case id
        case headline
        case summary
        case author
        case timestamp = "created_at"
        case url
        case symbols
    }
}

/// Represents a position on the Alpaca platform
struct AlpacaPosition: Codable {
    let assetId: String
    let symbol: String
    let exchange: String
    let assetClass: String
    let avgEntryPrice: String
    let qty: String
    let side: String
    let marketValue: String
    let costBasis: String
    let unrealizedPl: String
    let unrealizedPlpc: String
    let unrealizedIntradayPl: String
    let unrealizedIntradayPlpc: String
    let currentPrice: String
    let lastdayPrice: String
    let changeToday: String
    
    enum CodingKeys: String, CodingKey {
        case assetId = "asset_id"
        case symbol
        case exchange
        case assetClass = "asset_class"
        case avgEntryPrice = "avg_entry_price"
        case qty
        case side
        case marketValue = "market_value"
        case costBasis = "cost_basis"
        case unrealizedPl = "unrealized_pl"
        case unrealizedPlpc = "unrealized_plpc"
        case unrealizedIntradayPl = "unrealized_intraday_pl"
        case unrealizedIntradayPlpc = "unrealized_intraday_plpc"
        case currentPrice = "current_price"
        case lastdayPrice = "lastday_price"
        case changeToday = "change_today"
    }
}

/// Represents an Alpaca trading account
struct AlpacaAccount: Codable {
    let id: String
    let accountNumber: String
    let status: String
    let currency: String
    let cash: String
    let portfolioValue: String
    let pattern_day_trader: Bool
    let trading_blocked: Bool
    let transfers_blocked: Bool
    let account_blocked: Bool
    let created_at: Date
    let trade_suspended_by_user: Bool
    let multiplier: String
    let shorting_enabled: Bool
    let long_market_value: String
    let short_market_value: String
    let equity: String
    let last_equity: String
    let initial_margin: String
    let maintenance_margin: String
    let last_maintenance_margin: String
    let daytrading_buying_power: String
    let buying_power: String
    let regt_buying_power: String
    let non_marginable_buying_power: String
    let sma: String
    let daytrade_count: Int
    
    enum CodingKeys: String, CodingKey {
        case id
        case accountNumber = "account_number"
        case status
        case currency
        case cash
        case portfolioValue = "portfolio_value"
        case pattern_day_trader
        case trading_blocked
        case transfers_blocked
        case account_blocked
        case created_at
        case trade_suspended_by_user
        case multiplier
        case shorting_enabled
        case long_market_value
        case short_market_value
        case equity
        case last_equity
        case initial_margin
        case maintenance_margin
        case last_maintenance_margin
        case daytrading_buying_power
        case buying_power
        case regt_buying_power
        case non_marginable_buying_power
        case sma
        case daytrade_count
    }
}
