import Foundation

/// Represents a single holding in a user's investment portfolio
/// Conforms to Identifiable for unique identification and Codable for persistence
struct PortfolioHolding: Identifiable, Codable {
    let id: UUID         // Unique identifier for the holding
    let symbol: String   // Stock symbol (e.g., "AAPL" for Apple)
    let shares: Double   // Number of shares owned (Double to support fractional shares)
    let purchasePrice: Double  // Price per share at time of purchase
    let purchaseDate: Date    // Date when the shares were purchased
    
    /// Initializes a new portfolio holding
    /// - Parameters:
    ///   - id: Unique identifier (auto-generated if not provided)
    ///   - symbol: Stock ticker symbol
    ///   - shares: Number of shares purchased
    ///   - purchasePrice: Price per share at purchase
    ///   - purchaseDate: Date of purchase (defaults to current date if not specified)
    init(id: UUID = UUID(), symbol: String, shares: Double, purchasePrice: Double, purchaseDate: Date = Date()) {
        self.id = id
        self.symbol = symbol
        self.shares = shares
        self.purchasePrice = purchasePrice
        self.purchaseDate = purchaseDate
    }
}
