import Foundation

/// Represents a technical indicator type with its parameters
public enum IndicatorType: Hashable {
    case sma(period: Int)
    case ema(period: Int)
    case rsi(period: Int)
    case macd(fastPeriod: Int, slowPeriod: Int, signalPeriod: Int)
    
    /// Returns a human-readable description of the indicator
    public var description: String {
        switch self {
        case .sma(let period):
            return "Simple Moving Average (\(period) periods)"
        case .ema(let period):
            return "Exponential Moving Average (\(period) periods)"
        case .rsi(let period):
            return "Relative Strength Index (\(period) periods)"
        case .macd(let fast, let slow, let signal):
            return "MACD (\(fast),\(slow),\(signal))"
        }
    }
    
    /// Returns the default period for each indicator type
    public var defaultPeriod: Int {
        switch self {
        case .sma:
            return 20
        case .ema:
            return 20
        case .rsi:
            return 14
        case .macd:
            return 12 // Fast period is considered the default
        }
    }
    
    /// Returns whether the indicator is an overlay on the price chart
    public var isOverlay: Bool {
        switch self {
        case .sma, .ema:
            return true
        case .rsi, .macd:
            return false
        }
    }
    
    /// Returns the recommended y-axis range for the indicator
    public var recommendedRange: ClosedRange<Double>? {
        switch self {
        case .sma, .ema:
            return nil // Uses price range
        case .rsi:
            return 0...100
        case .macd:
            return nil // Dynamic range based on values
        }
    }
}
