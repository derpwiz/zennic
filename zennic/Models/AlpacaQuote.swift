import Foundation

/// Represents a quote from Alpaca API
struct AlpacaQuote: Codable {
    let symbol: String
    let timestamp: Date
    let bidPrice: Double
    let bidSize: Int
    let askPrice: Double
    let askSize: Int
    
    private enum CodingKeys: String, CodingKey {
        case symbol = "S"
        case timestamp = "t"
        case bidPrice = "bp"
        case bidSize = "bs"
        case askPrice = "ap"
        case askSize = "as"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.symbol = try container.decode(String.self, forKey: .symbol)
        self.timestamp = try container.decode(Date.self, forKey: .timestamp)
        self.bidPrice = try container.decode(Double.self, forKey: .bidPrice)
        self.bidSize = try container.decode(Int.self, forKey: .bidSize)
        self.askPrice = try container.decode(Double.self, forKey: .askPrice)
        self.askSize = try container.decode(Int.self, forKey: .askSize)
    }
}

/// Response wrapper for quote data
struct QuoteResponse: Codable {
    let quote: AlpacaQuote
    
    private enum CodingKeys: String, CodingKey {
        case quote = "quote"
    }
}
