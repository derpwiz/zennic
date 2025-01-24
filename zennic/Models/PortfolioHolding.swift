import Foundation

/// Represents a single holding in a user's investment portfolio
/// Conforms to Identifiable for unique identification and Codable for persistence
struct PortfolioHolding: Identifiable, Codable {
    let symbol: String
    let quantity: Double
    let averagePrice: Double
    let marketValue: Double
    let unrealizedPL: Double
    let currentPrice: Double
    let lastDayPrice: Double
    let changeToday: Double
    let assetId: String
    let assetClass: String
    
    var id: String { symbol }
    
    /// Initializes a new portfolio holding
    /// - Parameters:
    ///   - symbol: Stock ticker symbol
    ///   - quantity: Number of shares owned
    ///   - averagePrice: Average price per share
    ///   - marketValue: Current market value of the holding
    ///   - unrealizedPL: Unrealized profit/loss
    ///   - currentPrice: Current market price per share
    ///   - lastDayPrice: Last day's closing price
    ///   - changeToday: Change in price today
    ///   - assetId: Unique identifier for the asset
    ///   - assetClass: Class of the asset (e.g., stock, option, etc.)
    init(symbol: String, quantity: Double, averagePrice: Double, marketValue: Double, unrealizedPL: Double, currentPrice: Double, lastDayPrice: Double, changeToday: Double, assetId: String, assetClass: String) {
        self.symbol = symbol
        self.quantity = quantity
        self.averagePrice = averagePrice
        self.marketValue = marketValue
        self.unrealizedPL = unrealizedPL
        self.currentPrice = currentPrice
        self.lastDayPrice = lastDayPrice
        self.changeToday = changeToday
        self.assetId = assetId
        self.assetClass = assetClass
    }
    
    /// Initializes a new portfolio holding from an Alpaca position
    /// - Parameter position: Alpaca position object
    init(from position: AlpacaPosition) {
        self.symbol = position.symbol
        self.quantity = Double(position.qty) ?? 0
        self.averagePrice = Double(position.avgEntryPrice) ?? 0
        self.marketValue = Double(position.marketValue) ?? 0
        self.unrealizedPL = Double(position.unrealizedPl) ?? 0
        self.currentPrice = Double(position.currentPrice) ?? 0
        self.lastDayPrice = Double(position.lastdayPrice) ?? 0
        self.changeToday = Double(position.changeToday) ?? 0
        self.assetId = position.assetId
        self.assetClass = position.assetClass
    }
    
    var percentageChange: Double {
        guard lastDayPrice > 0 else { return 0 }
        return ((currentPrice - lastDayPrice) / lastDayPrice) * 100
    }
    
    var unrealizedPLPercentage: Double {
        guard averagePrice > 0 else { return 0 }
        return (unrealizedPL / (averagePrice * quantity)) * 100
    }
}
