import Foundation
import SwiftUI
import Charts

/// Represents a point on a technical indicator line
public struct IndicatorValue {
    public let date: Date
    public let value: Double
    public var x: Double {
        date.timeIntervalSince1970
    }
    public var y: Double {
        value
    }
    
    public init(date: Date, value: Double) {
        self.date = date
        self.value = value
    }
}

/// Container for technical indicator data
public struct IndicatorData {
    public let type: IndicatorType
    public let period: Int
    public let points: [IndicatorValue]
    public let additionalData: [String: [IndicatorValue]]
    
    public init(type: IndicatorType, period: Int, points: [IndicatorValue], additionalData: [String: [IndicatorValue]] = [:]) {
        self.type = type
        self.period = period
        self.points = points
        self.additionalData = additionalData
    }
}

/// Technical Analysis Calculator
public class TechnicalAnalysis {
    // MARK: - Moving Averages
    
    public static func calculateSMA(prices: [Double], period: Int) -> [Double] {
        guard period > 0 else { return [] }
        var sma: [Double] = []
        
        for i in 0..<prices.count {
            if i < period - 1 {
                sma.append(0)
                continue
            }
            
            let sum = prices[(i - period + 1)...i].reduce(0, +)
            sma.append(sum / Double(period))
        }
        
        return sma
    }
    
    public static func calculateEMA(prices: [Double], period: Int) -> [Double] {
        guard period > 0 else { return [] }
        var ema: [Double] = []
        let multiplier = 2.0 / Double(period + 1)
        
        // First EMA is SMA
        let firstSMA = prices[0..<period].reduce(0, +) / Double(period)
        ema.append(firstSMA)
        
        for i in period..<prices.count {
            let currentEMA = (prices[i] - ema.last!) * multiplier + ema.last!
            ema.append(currentEMA)
        }
        
        return ema
    }
    
    public static func calculateWMA(prices: [Double], period: Int) -> [Double] {
        guard period > 0 else { return [] }
        
        var wma: [Double] = []
        let weights = Array(1...period)
        let weightSum = weights.reduce(0, +)
        
        for i in 0..<prices.count {
            if i < period - 1 {
                wma.append(0)
                continue
            }
            
            var sum = 0.0
            for j in 0..<period {
                sum += prices[i - j] * Double(weights[period - 1 - j])
            }
            wma.append(sum / Double(weightSum))
        }
        return wma
    }
    
    public static func calculateDEMA(prices: [Double], period: Int) -> [Double] {
        let ema1 = calculateEMA(prices: prices, period: period)
        let ema2 = calculateEMA(prices: ema1, period: period)
        
        return zip(ema1, ema2).map { 2 * $0 - $1 }
    }
    
    public static func calculateTEMA(prices: [Double], period: Int) -> [Double] {
        let ema1 = calculateEMA(prices: prices, period: period)
        let ema2 = calculateEMA(prices: ema1, period: period)
        let ema3 = calculateEMA(prices: ema2, period: period)
        
        return zip(zip(ema1, ema2), ema3).map { 3 * $0.0 - 3 * $0.1 + $1 }
    }
    
    // MARK: - Momentum Indicators
    
    public static func calculateRSI(prices: [Double], period: Int = 14) -> [Double] {
        guard prices.count > period else { return [] }
        var rsi: [Double] = []
        var gains: [Double] = []
        var losses: [Double] = []
        
        // Calculate price changes
        for i in 1..<prices.count {
            let change = prices[i] - prices[i-1]
            gains.append(max(change, 0))
            losses.append(max(-change, 0))
        }
        
        // Calculate average gain and loss
        var avgGain = gains[0..<period].reduce(0, +) / Double(period)
        var avgLoss = losses[0..<period].reduce(0, +) / Double(period)
        
        // Calculate RSI
        for i in period..<prices.count {
            let rs = avgGain / avgLoss
            let currentRSI = 100 - (100 / (1 + rs))
            rsi.append(currentRSI)
            
            // Update average gain and loss
            avgGain = (avgGain * Double(period - 1) + gains[i]) / Double(period)
            avgLoss = (avgLoss * Double(period - 1) + losses[i]) / Double(period)
        }
        
        return rsi
    }
    
    public static func calculateMACD(prices: [Double], shortPeriod: Int = 12, longPeriod: Int = 26, signalPeriod: Int = 9) -> (macd: [Double], signal: [Double], histogram: [Double]) {
        let shortEMA = calculateEMA(prices: prices, period: shortPeriod)
        let longEMA = calculateEMA(prices: prices, period: longPeriod)
        
        var macd: [Double] = []
        for i in 0..<min(shortEMA.count, longEMA.count) {
            macd.append(shortEMA[i] - longEMA[i])
        }
        
        let signal = calculateEMA(prices: macd, period: signalPeriod)
        
        var histogram: [Double] = []
        for i in 0..<min(macd.count, signal.count) {
            histogram.append(macd[i] - signal[i])
        }
        
        return (macd, signal, histogram)
    }
    
    public static func calculateCCI(high: [Double], low: [Double], close: [Double], period: Int) -> [Double] {
        var cci: [Double] = []
        let typicalPrices = zip(zip(high, low), close).map { ($0.0 + $0.1 + $1) / 3.0 }
        
        for i in 0..<typicalPrices.count {
            if i < period - 1 {
                cci.append(0)
                continue
            }
            
            let slice = Array(typicalPrices[(i - period + 1)...i])
            let sma = slice.reduce(0, +) / Double(period)
            let meanDeviation = slice.map { abs($0 - sma) }.reduce(0, +) / Double(period)
            cci.append((typicalPrices[i] - sma) / (0.015 * meanDeviation))
        }
        
        return cci
    }
    
    public static func calculateStochastic(high: [Double], low: [Double], close: [Double], period: Int) -> (k: [Double], d: [Double]) {
        var k: [Double] = []
        
        for i in 0..<close.count {
            if i < period - 1 {
                k.append(0)
                continue
            }
            
            let highSlice = Array(high[(i - period + 1)...i])
            let lowSlice = Array(low[(i - period + 1)...i])
            
            let highest = highSlice.max() ?? 0
            let lowest = lowSlice.min() ?? 0
            
            k.append(((close[i] - lowest) / (highest - lowest)) * 100)
        }
        
        let d = calculateSMA(prices: k, period: 3)
        return (k, d)
    }
    
    public static func calculateWilliamsR(high: [Double], low: [Double], close: [Double], period: Int) -> [Double] {
        var r: [Double] = []
        
        for i in 0..<close.count {
            if i < period - 1 {
                r.append(0)
                continue
            }
            
            let highSlice = Array(high[(i - period + 1)...i])
            let lowSlice = Array(low[(i - period + 1)...i])
            
            let highest = highSlice.max() ?? 0
            let lowest = lowSlice.min() ?? 0
            
            r.append(((highest - close[i]) / (highest - lowest)) * -100)
        }
        
        return r
    }
    
    // MARK: - Volume Indicators
    
    public static func calculateOBV(close: [Double], volume: [Double]) -> [Double] {
        var obv: [Double] = []
        
        for i in 0..<close.count {
            if i == 0 {
                obv.append(0)
                continue
            }
            
            if close[i] > close[i-1] {
                obv.append(obv.last! + volume[i])
            } else if close[i] < close[i-1] {
                obv.append(obv.last! - volume[i])
            } else {
                obv.append(obv.last!)
            }
        }
        
        return obv
    }
    
    public static func calculateVWAP(high: [Double], low: [Double], close: [Double], volume: [Double]) -> [Double] {
        var cumulativeTPV = 0.0 // Typical Price * Volume
        var cumulativeVolume = 0.0
        var vwap: [Double] = []
        
        for i in 0..<close.count {
            let typicalPrice = (high[i] + low[i] + close[i]) / 3.0
            cumulativeTPV += typicalPrice * volume[i]
            cumulativeVolume += volume[i]
            vwap.append(cumulativeTPV / cumulativeVolume)
        }
        
        return vwap
    }
    
    // MARK: - Pattern Recognition
    
    public static func calculateIchimokuCloud(
        high: [Double],
        low: [Double],
        conversionPeriod: Int = 9,
        basePeriod: Int = 26,
        leadingSpanBPeriod: Int = 52,
        displacement: Int = 26
    ) -> (conversion: [Double], base: [Double], leadingSpanA: [Double], leadingSpanB: [Double]) {
        
        func calculateLine(_ period: Int) -> [Double] {
            var line: [Double] = []
            
            for i in 0..<high.count {
                if i < period - 1 {
                    line.append(0)
                    continue
                }
                
                let highSlice = Array(high[(i - period + 1)...i])
                let lowSlice = Array(low[(i - period + 1)...i])
                line.append((highSlice.max()! + lowSlice.min()!) / 2.0)
            }
            
            return line
        }
        
        let conversion = calculateLine(conversionPeriod)
        let base = calculateLine(basePeriod)
        
        var leadingSpanA: [Double] = []
        var leadingSpanB: [Double] = []
        
        for i in 0..<high.count {
            if i < displacement {
                leadingSpanA.append(0)
                leadingSpanB.append(0)
                continue
            }
            
            if i < basePeriod - 1 {
                leadingSpanA.append(0)
                leadingSpanB.append(0)
                continue
            }
            
            leadingSpanA.append((conversion[i - displacement] + base[i - displacement]) / 2.0)
        }
        
        let spanB = calculateLine(leadingSpanBPeriod)
        for i in 0..<high.count {
            if i < displacement {
                leadingSpanB.append(0)
                continue
            }
            
            leadingSpanB.append(spanB[i - displacement])
        }
        
        return (conversion, base, leadingSpanA, leadingSpanB)
    }
    
    public static func calculateParabolicSAR(
        high: [Double],
        low: [Double],
        accelerationFactor: Double = 0.02,
        maxAcceleration: Double = 0.2
    ) -> [Double] {
        var sar: [Double] = []
        var isUptrend = true
        var extremePoint = high[0]
        var acceleration = accelerationFactor
        
        sar.append(low[0])
        
        for i in 1..<high.count {
            sar.append(sar.last! + acceleration * (extremePoint - sar.last!))
            
            if isUptrend {
                if low[i] < sar.last! {
                    isUptrend = false
                    sar[sar.count - 1] = extremePoint
                    extremePoint = low[i]
                    acceleration = accelerationFactor
                } else {
                    if high[i] > extremePoint {
                        extremePoint = high[i]
                        acceleration = min(acceleration + accelerationFactor, maxAcceleration)
                    }
                }
            } else {
                if high[i] > sar.last! {
                    isUptrend = true
                    sar[sar.count - 1] = extremePoint
                    extremePoint = high[i]
                    acceleration = accelerationFactor
                } else {
                    if low[i] < extremePoint {
                        extremePoint = low[i]
                        acceleration = min(acceleration + accelerationFactor, maxAcceleration)
                    }
                }
            }
        }
        
        return sar
    }
    
    public static func calculateZigZag(high: [Double], low: [Double], percentageChange: Double) -> [Double] {
        var zigzag: [Double] = []
        var pivots: [(index: Int, value: Double)] = []
        var isUptrend = true
        
        // Find initial direction
        var maxValue = high[0]
        var minValue = low[0]
        var maxIndex = 0
        var minIndex = 0
        
        for i in 1..<high.count {
            if high[i] > maxValue {
                maxValue = high[i]
                maxIndex = i
            }
            if low[i] < minValue {
                minValue = low[i]
                minIndex = i
            }
            
            let changeFromMax = (maxValue - low[i]) / maxValue * 100
            let changeFromMin = (high[i] - minValue) / minValue * 100
            
            if changeFromMax >= percentageChange && isUptrend {
                pivots.append((maxIndex, maxValue))
                isUptrend = false
                minValue = low[i]
                minIndex = i
            } else if changeFromMin >= percentageChange && !isUptrend {
                pivots.append((minIndex, minValue))
                isUptrend = true
                maxValue = high[i]
                maxIndex = i
            }
        }
        
        // Connect the pivots
        for i in 0..<pivots.count - 1 {
            let start = pivots[i]
            let end = pivots[i + 1]
            let slope = (end.value - start.value) / Double(end.index - start.index)
            
            for j in start.index...end.index {
                zigzag.append(start.value + slope * Double(j - start.index))
            }
        }
        
        return zigzag
    }
    
    public static func calculatePivotPoints(high: Double, low: Double, close: Double) -> (pp: Double, r1: Double, r2: Double, r3: Double, s1: Double, s2: Double, s3: Double) {
        let pp = (high + low + close) / 3.0
        let r1 = (2.0 * pp) - low
        let r2 = pp + (high - low)
        let r3 = high + 2.0 * (pp - low)
        let s1 = (2.0 * pp) - high
        let s2 = pp - (high - low)
        let s3 = low - 2.0 * (high - pp)
        
        return (pp, r1, r2, r3, s1, s2, s3)
    }
    
    // MARK: - Volatility Indicators
    
    public static func calculateBollingerBands(prices: [Double], period: Int = 20, standardDeviations: Double = 2.0) -> (middle: [Double], upper: [Double], lower: [Double]) {
        let sma = calculateSMA(prices: prices, period: period)
        var upper: [Double] = []
        var lower: [Double] = []
        
        for i in 0..<prices.count {
            if i < period - 1 {
                upper.append(0)
                lower.append(0)
                continue
            }
            
            let slice = prices[(i - period + 1)...i]
            let std = standardDeviation(Array(slice))
            upper.append(sma[i] + (standardDeviations * std))
            lower.append(sma[i] - (standardDeviations * std))
        }
        
        return (sma, upper, lower)
    }
    
    public static func calculateATR(high: [Double], low: [Double], close: [Double], period: Int) -> [Double] {
        var atr: [Double] = []
        
        for i in 0..<high.count {
            if i < period - 1 {
                atr.append(0)
                continue
            }
            
            let highLow = zip(high, low).map { $0 - $1 }
            let highClose = zip(high, close).map { abs($0 - $1) }
            let lowClose = zip(low, close).map { abs($0 - $1) }
            let tr = zip(highLow, zip(highClose, lowClose)).map { max($0, max($1.0, $1.1)) }
            atr.append(tr.reduce(0, +) / Double(period))
        }
        
        return atr
    }
    
    public static func calculateStandardDeviation(prices: [Double], period: Int) -> [Double] {
        var std: [Double] = []
        
        for i in 0..<prices.count {
            if i < period - 1 {
                std.append(0)
                continue
            }
            
            let slice = prices[(i - period + 1)...i]
            std.append(standardDeviation(Array(slice)))
        }
        
        return std
    }
    
    public static func calculateKeltnerChannels(high: [Double], low: [Double], close: [Double], period: Int, multiplier: Double) -> (middle: [Double], upper: [Double], lower: [Double]) {
        let ema = calculateEMA(prices: close, period: period)
        let atr = calculateATR(high: high, low: low, close: close, period: period)
        
        var upper: [Double] = []
        var lower: [Double] = []
        
        for i in 0..<close.count {
            if i < period - 1 {
                upper.append(0)
                lower.append(0)
                continue
            }
            
            upper.append(ema[i] + (multiplier * atr[i]))
            lower.append(ema[i] - (multiplier * atr[i]))
        }
        
        return (ema, upper, lower)
    }
    
    public static func calculateDonchianChannels(high: [Double], low: [Double], period: Int) -> (middle: [Double], upper: [Double], lower: [Double]) {
        var upper: [Double] = []
        var lower: [Double] = []
        
        for i in 0..<high.count {
            if i < period - 1 {
                upper.append(0)
                lower.append(0)
                continue
            }
            
            let highSlice = Array(high[(i - period + 1)...i])
            let lowSlice = Array(low[(i - period + 1)...i])
            upper.append(highSlice.max() ?? 0)
            lower.append(lowSlice.min() ?? 0)
        }
        
        return ([], upper, lower)
    }
    
    // MARK: - Helper Functions
    
    private static func standardDeviation(_ values: [Double]) -> Double {
        let mean = values.reduce(0.0, +) / Double(values.count)
        let sumSquaredDiff = values.reduce(0.0) { $0 + pow($1 - mean, 2) }
        return sqrt(sumSquaredDiff / Double(values.count))
    }
}
