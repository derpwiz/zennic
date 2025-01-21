import Foundation

/// Advanced pattern recognition system for technical analysis
class PatternRecognition {
    // MARK: - Candlestick Patterns
    
    enum CandlePattern: String {
        case doji = "Doji"
        case hammer = "Hammer"
        case shootingStar = "Shooting Star"
        case engulfing = "Engulfing"
        case morningStarDoji = "Morning Star Doji"
        case eveningStarDoji = "Evening Star Doji"
        case threeWhiteSoldiers = "Three White Soldiers"
        case threeBlackCrows = "Three Black Crows"
        case piercingLine = "Piercing Line"
        case darkCloudCover = "Dark Cloud Cover"
        
        var isReversalPattern: Bool {
            switch self {
            case .doji: return false
            case .hammer, .shootingStar, .engulfing, .morningStarDoji,
                 .eveningStarDoji, .threeWhiteSoldiers, .threeBlackCrows,
                 .piercingLine, .darkCloudCover:
                return true
            }
        }
    }
    
    struct PatternMatch {
        let pattern: CandlePattern
        let startIndex: Int
        let endIndex: Int
        let reliability: Double // 0-1 score
        let direction: TrendDirection
    }
    
    /// Detect candlestick patterns in price data
    static func detectCandlePatterns(candles: [CandleStickData]) -> [PatternMatch] {
        var patterns: [PatternMatch] = []
        
        // Minimum required candles for pattern detection
        guard candles.count >= 5 else { return [] }
        
        for i in 0..<candles.count {
            // Single candle patterns
            if let dojiPattern = detectDoji(at: i, in: candles) {
                patterns.append(dojiPattern)
            }
            if let hammerPattern = detectHammer(at: i, in: candles) {
                patterns.append(hammerPattern)
            }
            
            // Two candle patterns
            if i < candles.count - 1 {
                if let engulfingPattern = detectEngulfing(at: i, in: candles) {
                    patterns.append(engulfingPattern)
                }
            }
            
            // Three candle patterns
            if i < candles.count - 2 {
                if let starPattern = detectStar(at: i, in: candles) {
                    patterns.append(starPattern)
                }
            }
        }
        
        return patterns
    }
    
    // MARK: - Chart Patterns
    
    enum ChartPattern: String {
        case headAndShoulders = "Head and Shoulders"
        case inverseHeadAndShoulders = "Inverse Head and Shoulders"
        case doubleTop = "Double Top"
        case doubleBottom = "Double Bottom"
        case tripleTop = "Triple Top"
        case tripleBottom = "Triple Bottom"
        case ascendingTriangle = "Ascending Triangle"
        case descendingTriangle = "Descending Triangle"
        case symmetricalTriangle = "Symmetrical Triangle"
        case channel = "Channel"
        case wedge = "Wedge"
        case cup = "Cup"
        case cupWithHandle = "Cup with Handle"
        case flagPole = "Flag Pole"
    }
    
    struct ChartPatternMatch {
        let pattern: ChartPattern
        let startIndex: Int
        let endIndex: Int
        let reliability: Double
        let direction: TrendDirection
        let targetPrice: Double
        let stopLoss: Double
    }
    
    /// Detect chart patterns in price data
    static func detectChartPatterns(prices: [Double], highs: [Double], lows: [Double]) -> [ChartPatternMatch] {
        var patterns: [ChartPatternMatch] = []
        
        // Head and Shoulders
        if let hsPattern = detectHeadAndShoulders(prices: prices) {
            patterns.append(hsPattern)
        }
        
        // Double Top/Bottom
        if let dtPattern = detectDoubleTopBottom(prices: prices, highs: highs, lows: lows) {
            patterns.append(dtPattern)
        }
        
        // Triangle Patterns
        if let trianglePattern = detectTriangles(prices: prices, highs: highs, lows: lows) {
            patterns.append(trianglePattern)
        }
        
        return patterns
    }
    
    // MARK: - Harmonic Patterns
    
    enum HarmonicPattern: String {
        case gartley = "Gartley"
        case butterfly = "Butterfly"
        case bat = "Bat"
        case crab = "Crab"
        case shark = "Shark"
        case cypher = "Cypher"
    }
    
    struct HarmonicPatternMatch {
        let pattern: HarmonicPattern
        let points: [Int] // Indices of XABCD points
        let ratios: [String: Double]
        let reliability: Double
        let direction: TrendDirection
        let targetPrice: Double
    }
    
    /// Detect harmonic patterns in price data
    static func detectHarmonicPatterns(prices: [Double]) -> [HarmonicPatternMatch] {
        var patterns: [HarmonicPatternMatch] = []
        
        // Minimum required points for harmonic pattern detection
        guard prices.count >= 5 else { return [] }
        
        // Detect potential swing points
        let swings = detectSwingPoints(prices: prices)
        
        // For each set of 5 swing points, check for harmonic patterns
        for i in 0...(swings.count - 5) {
            let points = Array(swings[i..<(i + 5)])
            
            // Check Gartley pattern
            if let gartley = validateGartley(points: points, prices: prices) {
                patterns.append(gartley)
            }
            
            // Check Butterfly pattern
            if let butterfly = validateButterfly(points: points, prices: prices) {
                patterns.append(butterfly)
            }
            
            // Additional harmonic patterns...
        }
        
        return patterns
    }
    
    // MARK: - Elliott Wave Patterns
    
    struct ElliottWave {
        let degree: WaveDegree
        let waves: [WaveSegment]
        let confidence: Double
        let completion: Double // 0-1 indicating wave completion
    }
    
    enum WaveDegree: String {
        case grand = "Grand Supercycle"
        case supercycle = "Supercycle"
        case cycle = "Cycle"
        case primary = "Primary"
        case intermediate = "Intermediate"
        case minor = "Minor"
        case minute = "Minute"
        case minuette = "Minuette"
        case subminuette = "Subminuette"
    }
    
    struct WaveSegment {
        let number: Int // 1-5 for impulse, A-C for correction
        let startIndex: Int
        let endIndex: Int
        let price: (start: Double, end: Double)
        let subwaves: [WaveSegment]?
        let isImpulse: Bool
    }
    
    /// Detect Elliott Wave patterns in price data
    static func detectElliottWaves(prices: [Double]) -> ElliottWave? {
        // Implement Elliott Wave detection algorithm
        // This is a complex pattern recognition task that requires:
        // 1. Identifying trend changes
        // 2. Measuring wave relationships
        // 3. Applying Elliott Wave rules and guidelines
        // 4. Calculating Fibonacci relationships
        return nil
    }
    
    // MARK: - Helper Methods
    
    private static func detectDoji(at index: Int, in candles: [CandleStickData]) -> PatternMatch? {
        let candle = candles[index]
        let bodySize = abs(candle.close - candle.open)
        let totalSize = candle.high - candle.low
        
        // Doji has very small body compared to total size
        if bodySize / totalSize < 0.1 {
            return PatternMatch(
                pattern: .doji,
                startIndex: index,
                endIndex: index,
                reliability: 0.7,
                direction: .neutral
            )
        }
        return nil
    }
    
    private static func detectHammer(at index: Int, in candles: [CandleStickData]) -> PatternMatch? {
        let candle = candles[index]
        let bodySize = abs(candle.close - candle.open)
        let upperShadow = candle.high - max(candle.open, candle.close)
        let lowerShadow = min(candle.open, candle.close) - candle.low
        
        // Hammer has small upper shadow and long lower shadow
        if upperShadow < bodySize * 0.1 && lowerShadow > bodySize * 2 {
            return PatternMatch(
                pattern: .hammer,
                startIndex: index,
                endIndex: index,
                reliability: 0.8,
                direction: .up
            )
        }
        return nil
    }
    
    private static func detectEngulfing(at index: Int, in candles: [CandleStickData]) -> PatternMatch? {
        guard index > 0 else { return nil }
        
        let prev = candles[index - 1]
        let curr = candles[index]
        
        // Bullish engulfing
        if prev.close < prev.open && // Previous red candle
           curr.close > curr.open && // Current green candle
           curr.open < prev.close && // Opens below previous close
           curr.close > prev.open {  // Closes above previous open
            return PatternMatch(
                pattern: .engulfing,
                startIndex: index - 1,
                endIndex: index,
                reliability: 0.85,
                direction: .up
            )
        }
        
        // Bearish engulfing
        if prev.close > prev.open && // Previous green candle
           curr.close < curr.open && // Current red candle
           curr.open > prev.close && // Opens above previous close
           curr.close < prev.open {  // Closes below previous open
            return PatternMatch(
                pattern: .engulfing,
                startIndex: index - 1,
                endIndex: index,
                reliability: 0.85,
                direction: .down
            )
        }
        
        return nil
    }
    
    private static func detectStar(at index: Int, in candles: [CandleStickData]) -> PatternMatch? {
        guard index > 1 else { return nil }
        
        let first = candles[index - 2]
        let middle = candles[index - 1]
        let last = candles[index]
        
        // Morning Star
        if first.close < first.open && // First day down
           abs(middle.close - middle.open) < (first.high - first.low) * 0.1 && // Doji day
           last.close > last.open && // Third day up
           middle.high < first.close && // Gap down after first day
           middle.low > last.open { // Gap up before third day
            return PatternMatch(
                pattern: .morningStarDoji,
                startIndex: index - 2,
                endIndex: index,
                reliability: 0.9,
                direction: .up
            )
        }
        
        return nil
    }
    
    private static func detectSwingPoints(prices: [Double]) -> [Int] {
        var swings: [Int] = []
        
        // Simple swing detection using local maxima/minima
        for i in 2..<(prices.count - 2) {
            // Local maximum
            if prices[i] > prices[i-1] && prices[i] > prices[i-2] &&
               prices[i] > prices[i+1] && prices[i] > prices[i+2] {
                swings.append(i)
            }
            // Local minimum
            if prices[i] < prices[i-1] && prices[i] < prices[i-2] &&
               prices[i] < prices[i+1] && prices[i] < prices[i+2] {
                swings.append(i)
            }
        }
        
        return swings.sorted()
    }
}

// MARK: - Supporting Types

enum TrendDirection {
    case up
    case down
    case neutral
}

extension PatternRecognition {
    /// Calculate Fibonacci retracement levels
    static func fibonacciLevels(high: Double, low: Double) -> [Double] {
        let diff = high - low
        return [
            high,                    // 100%
            high - diff * 0.236,     // 23.6%
            high - diff * 0.382,     // 38.2%
            high - diff * 0.5,       // 50%
            high - diff * 0.618,     // 61.8%
            high - diff * 0.786,     // 78.6%
            low                      // 0%
        ]
    }
    
    /// Calculate Fibonacci extension levels
    static func fibonacciExtensions(start: Double, end: Double, retracement: Double) -> [Double] {
        let diff = end - start
        let direction = diff > 0 ? 1.0 : -1.0
        
        return [
            end,                     // 100%
            end + diff * 0.618 * direction,  // 161.8%
            end + diff * 1.0 * direction,    // 200%
            end + diff * 1.618 * direction,  // 261.8%
            end + diff * 2.0 * direction,    // 300%
            end + diff * 2.618 * direction   // 361.8%
        ]
    }
    
    /// Calculate pivot points
    static func pivotPoints(high: Double, low: Double, close: Double) -> (pp: Double, r1: Double, r2: Double, r3: Double, s1: Double, s2: Double, s3: Double) {
        let pp = (high + low + close) / 3
        
        // Standard pivot points
        let r1 = (2 * pp) - low
        let s1 = (2 * pp) - high
        let r2 = pp + (high - low)
        let s2 = pp - (high - low)
        let r3 = high + 2 * (pp - low)
        let s3 = low - 2 * (high - pp)
        
        return (pp, r1, r2, r3, s1, s2, s3)
    }
}
