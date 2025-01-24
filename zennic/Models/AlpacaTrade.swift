import Foundation

/// Represents a trade from Alpaca API
struct AlpacaTrade: Codable {
    let symbol: String
    let timestamp: Date
    let price: Double
    let size: Int
    let exchange: String
    let id: Int
    let tape: String
    
    private enum CodingKeys: String, CodingKey {
        case symbol = "S"
        case timestamp = "t"
        case price = "p"
        case size = "s"
        case exchange = "x"
        case id = "i"
        case tape = "z"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.symbol = try container.decode(String.self, forKey: .symbol)
        self.timestamp = try container.decode(Date.self, forKey: .timestamp)
        self.price = try container.decode(Double.self, forKey: .price)
        self.size = try container.decode(Int.self, forKey: .size)
        self.exchange = try container.decode(String.self, forKey: .exchange)
        self.id = try container.decode(Int.self, forKey: .id)
        self.tape = try container.decode(String.self, forKey: .tape)
    }
}

/// Response wrapper for trade data
struct TradeResponse: Codable {
    let trade: AlpacaTrade
    
    private enum CodingKeys: String, CodingKey {
        case trade = "trade"
    }
}
