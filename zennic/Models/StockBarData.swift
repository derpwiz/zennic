import Foundation

/// Represents a single candlestick bar of stock market data
public struct StockBarData: Identifiable, Codable, Equatable, Hashable {
    // MARK: - Properties
    
    /// Unique identifier for the bar
    public let id: UUID
    
    /// The timestamp of the bar
    public let timestamp: Date
    
    /// The opening price of the period
    public let openPrice: Double
    
    /// The highest price of the period
    public let highPrice: Double
    
    /// The lowest price of the period
    public let lowPrice: Double
    
    /// The closing price of the period
    public let closePrice: Double
    
    /// The trading volume for the period
    public let volume: Double
    
    /// The symbol this bar data represents
    public let symbol: String
    
    // MARK: - Computed Properties
    
    /// Whether the bar represents an upward price movement
    public var isUpward: Bool {
        closePrice >= openPrice
    }
    
    /// The price range of the bar
    public var priceRange: Double {
        highPrice - lowPrice
    }
    
    /// The body range of the candlestick
    public var bodyRange: Double {
        abs(closePrice - openPrice)
    }
    
    /// The upper shadow length
    public var upperShadow: Double {
        highPrice - max(openPrice, closePrice)
    }
    
    /// The lower shadow length
    public var lowerShadow: Double {
        min(openPrice, closePrice) - lowPrice
    }
    
    /// The typical price (average of high, low, and close)
    public var typicalPrice: Double {
        (highPrice + lowPrice + closePrice) / 3.0
    }
    
    // MARK: - Initialization
    
    /// Creates a new StockBarData instance
    /// - Parameters:
    ///   - symbol: The stock symbol
    ///   - timestamp: The timestamp of the bar
    ///   - openPrice: The opening price
    ///   - highPrice: The highest price
    ///   - lowPrice: The lowest price
    ///   - closePrice: The closing price
    ///   - volume: The trading volume
    public init(symbol: String,
         timestamp: Date,
         openPrice: Double,
         highPrice: Double,
         lowPrice: Double,
         closePrice: Double,
         volume: Double) {
        self.id = UUID()
        self.symbol = symbol
        self.timestamp = timestamp
        
        // Validate and normalize prices
        precondition(highPrice >= lowPrice, "High price must be greater than or equal to low price")
        precondition(openPrice >= lowPrice && openPrice <= highPrice, "Open price must be within high-low range")
        precondition(closePrice >= lowPrice && closePrice <= highPrice, "Close price must be within high-low range")
        precondition(volume >= 0, "Volume must be non-negative")
        
        self.openPrice = openPrice
        self.highPrice = highPrice
        self.lowPrice = lowPrice
        self.closePrice = closePrice
        self.volume = volume
    }
    
    // MARK: - Codable
    
    enum CodingKeys: String, CodingKey {
        case id
        case symbol
        case timestamp
        case openPrice = "open"
        case highPrice = "high"
        case lowPrice = "low"
        case closePrice = "close"
        case volume
    }
    
    // MARK: - Hashable
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    // MARK: - Equatable
    
    public static func == (lhs: StockBarData, rhs: StockBarData) -> Bool {
        lhs.id == rhs.id &&
        lhs.symbol == rhs.symbol &&
        lhs.timestamp == rhs.timestamp &&
        abs(lhs.openPrice - rhs.openPrice) < .ulpOfOne &&
        abs(lhs.highPrice - rhs.highPrice) < .ulpOfOne &&
        abs(lhs.lowPrice - rhs.lowPrice) < .ulpOfOne &&
        abs(lhs.closePrice - rhs.closePrice) < .ulpOfOne &&
        abs(lhs.volume - rhs.volume) < .ulpOfOne
    }
}

// MARK: - Mock Data Generation

extension StockBarData {
    /// Generates mock data for testing and preview purposes
    /// - Parameters:
    ///   - symbol: The stock symbol for the mock data
    ///   - days: Number of days of data to generate
    ///   - basePrice: Starting price for the mock data
    /// - Returns: An array of mock StockBarData
    public static func mockData(symbol: String = "AAPL",
                        days: Int = 5,
                        basePrice: Double = 150.0) -> [StockBarData] {
        let calendar = Calendar.current
        let today = Date()
        
        return (0..<days).map { index in
            let date = calendar.date(byAdding: .day, value: -index, to: today)!
            let randomChange = Double.random(in: -5...5)
            let open = basePrice + randomChange
            let high = open + Double.random(in: 0...3)
            let low = open - Double.random(in: 0...3)
            let close = Double.random(in: low...high)
            let volume = Double.random(in: 500000...1500000)
            
            return StockBarData(
                symbol: symbol,
                timestamp: date,
                openPrice: open,
                highPrice: high,
                lowPrice: low,
                closePrice: close,
                volume: volume
            )
        }
    }
    
    /// Creates a sample bar for testing
    public static var sample: StockBarData {
        StockBarData(
            symbol: "AAPL",
            timestamp: Date(),
            openPrice: 150.0,
            highPrice: 155.0,
            lowPrice: 148.0,
            closePrice: 152.0,
            volume: 1000000
        )
    }
}

// MARK: - Formatting Extensions

extension StockBarData {
    /// Formats a price value to a string with 2 decimal places
    /// - Parameter price: The price to format
    /// - Returns: A formatted string representation of the price
    public func formatPrice(_ price: Double) -> String {
        String(format: "%.2f", price)
    }
    
    /// Formats the volume to a human-readable string
    public var formattedVolume: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: volume)) ?? String(format: "%.0f", volume)
    }
    
    /// Returns a formatted string with all bar data
    public var description: String {
        """
        \(symbol) - \(timestamp.formatted())
        Open: \(formatPrice(openPrice))
        High: \(formatPrice(highPrice))
        Low: \(formatPrice(lowPrice))
        Close: \(formatPrice(closePrice))
        Volume: \(formattedVolume)
        """
    }
}
