import Foundation

struct PortfolioHolding: Identifiable, Codable {
    let id: UUID
    let symbol: String
    let shares: Double
    let purchasePrice: Double
    let purchaseDate: Date
    
    init(id: UUID = UUID(), symbol: String, shares: Double, purchasePrice: Double, purchaseDate: Date = Date()) {
        self.id = id
        self.symbol = symbol
        self.shares = shares
        self.purchasePrice = purchasePrice
        self.purchaseDate = purchaseDate
    }
}
