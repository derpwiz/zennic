import Foundation

/// Represents a single holding in a user's investment portfolio
/// Conforms to Identifiable for unique identification and Codable for persistence
struct PortfolioHolding: Identifiable, Codable {
    let id: UUID         // Unique identifier for the holding
    let symbol: String   // Stock symbol (e.g., "AAPL" for Apple)
    private(set) var shares: Double   // Number of shares owned (Double to support fractional shares)
    private(set) var purchasePrice: Double  // Price per share at time of purchase
    let purchaseDate: Date    // Date when the shares were purchased
    private(set) var currentPrice: Double?  // Current market price per share
    
    /// Initializes a new portfolio holding
    /// - Parameters:
    ///   - id: Unique identifier (auto-generated if not provided)
    ///   - symbol: Stock ticker symbol
    ///   - shares: Number of shares purchased
    ///   - purchasePrice: Price per share at purchase
    ///   - purchaseDate: Date of purchase (defaults to current date if not specified)
    /// - Throws: ValidationError if shares or price are invalid
    init(id: UUID = UUID(), symbol: String, shares: Double, purchasePrice: Double, purchaseDate: Date = Date()) throws {
        guard shares > 0 else {
            throw ValidationError.invalidShares
        }
        
        guard purchasePrice > 0 else {
            throw ValidationError.invalidPrice
        }
        
        self.id = id
        self.symbol = symbol
        self.shares = shares
        self.purchasePrice = purchasePrice
        self.purchaseDate = purchaseDate
        self.currentPrice = nil
    }
    
    /// Updates the current market price
    /// - Parameter price: Current market price per share
    /// - Throws: ValidationError if price is invalid
    mutating func updateCurrentPrice(_ price: Double) throws {
        guard price > 0 else {
            throw ValidationError.invalidPrice
        }
        self.currentPrice = price
    }
    
    /// Calculates the total cost basis of the holding
    var costBasis: Double {
        shares * purchasePrice
    }
    
    /// Calculates the current market value of the holding
    /// Returns nil if current price is not available
    var marketValue: Double? {
        guard let currentPrice = currentPrice else { return nil }
        return shares * currentPrice
    }
    
    /// Calculates the unrealized gain/loss
    /// Returns nil if current price is not available
    var unrealizedGainLoss: Double? {
        guard let marketValue = marketValue else { return nil }
        return marketValue - costBasis
    }
    
    /// Calculates the return on investment as a percentage
    /// Returns nil if current price is not available
    var roi: Double? {
        guard let marketValue = marketValue, costBasis > 0 else { return nil }
        return ((marketValue - costBasis) / costBasis) * 100
    }
}

/// Validation errors for portfolio holdings
enum ValidationError: Error {
    case invalidShares
    case invalidPrice
}
