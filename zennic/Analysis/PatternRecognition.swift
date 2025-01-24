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
    static func detectCandlePatterns(candles: [StockBarData]) -> [PatternMatch] {
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
        if let hsPattern = detectHeadAndShoulders(prices: prices, highs: highs, lows: lows) {
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
            if let gartley = validateGartleyPattern(points: points, prices: prices) {
                patterns.append(gartley)
            }
            
            // Check Butterfly pattern
            if let butterfly = validateButterflyPattern(points: points, prices: prices) {
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
    
    // MARK: - Chart Pattern Detection Methods
    
    private static func detectHeadAndShoulders(prices: [Double], highs: [Double], lows: [Double]) -> ChartPatternMatch? {
        guard prices.count >= 30 else { return nil }
        
        // Find local maxima for potential shoulders and head
        let peaks = findLocalMaxima(prices: highs, window: 5)
        guard peaks.count >= 3 else { return nil }
        
        // Find three peaks that form head and shoulders pattern
        for i in 0...(peaks.count - 3) {
            let leftShoulder = peaks[i]
            let head = peaks[i + 1]
            let rightShoulder = peaks[i + 2]
            
            // Verify pattern characteristics
            if isValidHeadAndShoulders(
                leftShoulder: (index: leftShoulder, price: highs[leftShoulder]),
                head: (index: head, price: highs[head]),
                rightShoulder: (index: rightShoulder, price: highs[rightShoulder]),
                prices: prices
            ) {
                // Calculate neckline and target
                let neckline = calculateNeckline(leftShoulder: leftShoulder, rightShoulder: rightShoulder, prices: lows)
                let patternHeight = highs[head] - neckline
                let targetPrice = neckline - patternHeight
                
                return ChartPatternMatch(
                    pattern: .headAndShoulders,
                    startIndex: leftShoulder,
                    endIndex: rightShoulder,
                    reliability: 0.8,
                    direction: .down,
                    targetPrice: targetPrice,
                    stopLoss: highs[head]
                )
            }
        }
        
        return nil
    }
    
    private static func detectDoubleTopBottom(prices: [Double], highs: [Double], lows: [Double]) -> ChartPatternMatch? {
        guard prices.count >= 20 else { return nil }
        
        // Look for double top
        let peaks = findLocalMaxima(prices: highs, window: 5)
        for i in 0..<(peaks.count - 1) {
            let firstPeak = peaks[i]
            let secondPeak = peaks[i + 1]
            
            // Check if peaks are similar in height
            let heightDiff = abs(highs[firstPeak] - highs[secondPeak])
            let avgHeight = (highs[firstPeak] + highs[secondPeak]) / 2
            
            if heightDiff / avgHeight < 0.02 && // Peaks within 2% of each other
               secondPeak - firstPeak >= 10 {   // Minimum spacing between peaks
                
                // Find the trough between peaks
                let trough = findMinimum(in: lows, start: firstPeak, end: secondPeak)
                let patternHeight = avgHeight - lows[trough]
                let targetPrice = lows[trough] - patternHeight
                
                return ChartPatternMatch(
                    pattern: .doubleTop,
                    startIndex: firstPeak,
                    endIndex: secondPeak,
                    reliability: 0.75,
                    direction: .down,
                    targetPrice: targetPrice,
                    stopLoss: avgHeight * 1.02
                )
            }
        }
        
        return nil
    }
    
    private static func detectTriangles(prices: [Double], highs: [Double], lows: [Double]) -> ChartPatternMatch? {
        guard prices.count >= 20 else { return nil }
        
        // Find potential triangle patterns using trend lines
        let highTrend = calculateTrendLine(prices: highs, window: 10)
        let lowTrend = calculateTrendLine(prices: lows, window: 10)
        
        // Check for converging trend lines
        if let convergencePoint = findConvergencePoint(highTrend: highTrend, lowTrend: lowTrend) {
            let slope1 = highTrend.slope
            let slope2 = lowTrend.slope
            
            // Determine triangle type
            if abs(slope1 + slope2) < 0.1 { // Symmetrical triangle
                let breakoutPrice = (highTrend.value(at: convergencePoint) + lowTrend.value(at: convergencePoint)) / 2
                let patternHeight = highTrend.value(at: 0) - lowTrend.value(at: 0)
                
                return ChartPatternMatch(
                    pattern: .symmetricalTriangle,
                    startIndex: 0,
                    endIndex: min(convergencePoint, prices.count - 1),
                    reliability: 0.7,
                    direction: slope1 < 0 ? .down : .up,
                    targetPrice: breakoutPrice + (patternHeight * (slope1 < 0 ? -1 : 1)),
                    stopLoss: breakoutPrice - (patternHeight * 0.5 * (slope1 < 0 ? -1 : 1))
                )
            }
        }
        
        return nil
    }
    
    // MARK: - Harmonic Pattern Detection Methods
    
    private static func validateGartleyPattern(points: [Int], prices: [Double]) -> HarmonicPatternMatch? {
        guard points.count >= 5 else { return nil }
        
        let xPrice = prices[points[0]]
        let aPrice = prices[points[1]]
        let bPrice = prices[points[2]]
        let cPrice = prices[points[3]]
        let dPrice = prices[points[4]]
        
        // Calculate Fibonacci ratios
        let xaDistance = abs(xPrice - aPrice)
        let abDistance = abs(aPrice - bPrice)
        let bcDistance = abs(bPrice - cPrice)
        let cdDistance = abs(cPrice - dPrice)
        
        // Verify Gartley pattern ratios
        let abRatio = abDistance / xaDistance
        let bcRatio = bcDistance / abDistance
        let cdRatio = cdDistance / bcDistance
        
        if (0.618...0.618).contains(abRatio) &&    // AB = 0.618 of XA
           (0.382...0.886).contains(bcRatio) &&    // BC = 0.382-0.886 of AB
           (1.27...1.618).contains(cdRatio) {      // CD = 1.27-1.618 of BC
            
            return HarmonicPatternMatch(
                pattern: .gartley,
                points: points,
                ratios: ["AB": abRatio, "BC": bcRatio, "CD": cdRatio],
                reliability: 0.8,
                direction: xPrice < dPrice ? .up : .down,
                targetPrice: dPrice + (xaDistance * 0.786 * (xPrice < dPrice ? 1 : -1))
            )
        }
        
        return nil
    }
    
    private static func validateButterflyPattern(points: [Int], prices: [Double]) -> HarmonicPatternMatch? {
        guard points.count >= 5 else { return nil }
        
        let xPrice = prices[points[0]]
        let aPrice = prices[points[1]]
        let bPrice = prices[points[2]]
        let cPrice = prices[points[3]]
        let dPrice = prices[points[4]]
        
        // Calculate Fibonacci ratios
        let xaDistance = abs(xPrice - aPrice)
        let abDistance = abs(aPrice - bPrice)
        let bcDistance = abs(bPrice - cPrice)
        let cdDistance = abs(cPrice - dPrice)
        
        // Verify Butterfly pattern ratios
        let abRatio = abDistance / xaDistance
        let bcRatio = bcDistance / abDistance
        let cdRatio = cdDistance / bcDistance
        
        if (0.786...0.786).contains(abRatio) &&    // AB = 0.786 of XA
           (0.382...0.886).contains(bcRatio) &&    // BC = 0.382-0.886 of AB
           (1.618...2.618).contains(cdRatio) {     // CD = 1.618-2.618 of BC
            
            return HarmonicPatternMatch(
                pattern: .butterfly,
                points: points,
                ratios: ["AB": abRatio, "BC": bcRatio, "CD": cdRatio],
                reliability: 0.75,
                direction: xPrice < dPrice ? .up : .down,
                targetPrice: dPrice + (xaDistance * 1.27 * (xPrice < dPrice ? 1 : -1))
            )
        }
        
        return nil
    }
    
    // MARK: - Helper Methods
    
    private static func findLocalMaxima(prices: [Double], window: Int) -> [Int] {
        var peaks: [Int] = []
        guard prices.count > window * 2 else { return peaks }
        
        for i in window..<(prices.count - window) {
            let leftWindow = prices[(i - window)...i]
            let rightWindow = prices[i...(i + window)]
            
            if prices[i] == leftWindow.max() && prices[i] == rightWindow.max() {
                peaks.append(i)
            }
        }
        
        return peaks
    }
    
    private static func isValidHeadAndShoulders(
        leftShoulder: (index: Int, price: Double),
        head: (index: Int, price: Double),
        rightShoulder: (index: Int, price: Double),
        prices: [Double]
    ) -> Bool {
        // Head should be higher than shoulders
        guard head.price > leftShoulder.price && head.price > rightShoulder.price else { return false }
        
        // Shoulders should be roughly equal height
        let shoulderDiff = abs(leftShoulder.price - rightShoulder.price)
        let avgShoulderHeight = (leftShoulder.price + rightShoulder.price) / 2
        guard shoulderDiff / avgShoulderHeight < 0.1 else { return false } // Within 10%
        
        // Pattern should be symmetrical
        let leftSpan = head.index - leftShoulder.index
        let rightSpan = rightShoulder.index - head.index
        guard abs(leftSpan - rightSpan) <= 5 else { return false } // Within 5 bars
        
        return true
    }
    
    private static func calculateNeckline(leftShoulder: Int, rightShoulder: Int, prices: [Double]) -> Double {
        let leftTrough = findMinimum(in: prices, start: leftShoulder, end: rightShoulder)
        let rightTrough = findMinimum(in: prices, start: leftTrough, end: rightShoulder)
        return (prices[leftTrough] + prices[rightTrough]) / 2
    }
    
    private static func findMinimum(in prices: [Double], start: Int, end: Int) -> Int {
        var minIndex = start
        var minValue = prices[start]
        
        for i in (start + 1)...end {
            if prices[i] < minValue {
                minValue = prices[i]
                minIndex = i
            }
        }
        
        return minIndex
    }
    
    private struct TrendLine {
        let slope: Double
        let intercept: Double
        
        func value(at x: Int) -> Double {
            return slope * Double(x) + intercept
        }
    }
    
    private static func calculateTrendLine(prices: [Double], window: Int) -> TrendLine {
        var sumX: Double = 0
        var sumY: Double = 0
        var sumXY: Double = 0
        var sumX2: Double = 0
        
        for i in 0..<window {
            let x = Double(i)
            let y = prices[i]
            
            sumX += x
            sumY += y
            sumXY += x * y
            sumX2 += x * x
        }
        
        let n = Double(window)
        let slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX)
        let intercept = (sumY - slope * sumX) / n
        
        return TrendLine(slope: slope, intercept: intercept)
    }
    
    private static func findConvergencePoint(highTrend: TrendLine, lowTrend: TrendLine) -> Int? {
        // Find where trend lines intersect
        let x = Int((lowTrend.intercept - highTrend.intercept) / (highTrend.slope - lowTrend.slope))
        return x >= 0 ? x : nil
    }
    
    
    private static func detectDoji(at index: Int, in candles: [StockBarData]) -> PatternMatch? {
        let candle = candles[index]
        let bodySize = abs(candle.closePrice - candle.openPrice)
        let totalSize = candle.highPrice - candle.lowPrice
        
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
    
    private static func detectHammer(at index: Int, in candles: [StockBarData]) -> PatternMatch? {
        let candle = candles[index]
        let bodySize = abs(candle.closePrice - candle.openPrice)
        let upperShadow = candle.highPrice - max(candle.openPrice, candle.closePrice)
        let lowerShadow = min(candle.openPrice, candle.closePrice) - candle.lowPrice
        
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
    
    private static func detectEngulfing(at index: Int, in candles: [StockBarData]) -> PatternMatch? {
        guard index > 0 else { return nil }
        
        let prev = candles[index - 1]
        let curr = candles[index]
        
        // Bullish engulfing
        if prev.closePrice < prev.openPrice && // Previous red candle
           curr.closePrice > curr.openPrice && // Current green candle
           curr.openPrice < prev.closePrice && // Opens below previous close
           curr.closePrice > prev.openPrice {  // Closes above previous open
            return PatternMatch(
                pattern: .engulfing,
                startIndex: index - 1,
                endIndex: index,
                reliability: 0.85,
                direction: .up
            )
        }
        
        // Bearish engulfing
        if prev.closePrice > prev.openPrice && // Previous green candle
           curr.closePrice < curr.openPrice && // Current red candle
           curr.openPrice > prev.closePrice && // Opens above previous close
           curr.closePrice < prev.openPrice {  // Closes below previous open
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
    
    private static func detectStar(at index: Int, in candles: [StockBarData]) -> PatternMatch? {
        guard index > 1 else { return nil }
        
        let first = candles[index - 2]
        let middle = candles[index - 1]
        let last = candles[index]
        
        // Morning Star
        if first.closePrice < first.openPrice && // First day down
           abs(middle.closePrice - middle.openPrice) < (first.highPrice - first.lowPrice) * 0.1 && // Doji day
           last.closePrice > last.openPrice && // Third day up
           middle.highPrice < first.closePrice && // Gap down after first day
           middle.lowPrice > last.openPrice { // Gap up before third day
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
