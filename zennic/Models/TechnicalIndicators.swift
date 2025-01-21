import Foundation

/// Technical indicator types available for charts
enum IndicatorType: String, CaseIterable {
    // Trend Indicators
    case sma = "Simple Moving Average"
    case ema = "Exponential Moving Average"
    case wma = "Weighted Moving Average"
    case dema = "Double Exponential MA"
    case tema = "Triple Exponential MA"
    case trix = "Triple Exponential Average"
    
    // Momentum Indicators
    case rsi = "Relative Strength Index"
    case macd = "MACD"
    case cci = "Commodity Channel Index"
    case stochastic = "Stochastic Oscillator"
    case williamsR = "Williams %R"
    case mfi = "Money Flow Index"
    case roc = "Rate of Change"
    case ppo = "Percentage Price Oscillator"
    
    // Volatility Indicators
    case bollingerBands = "Bollinger Bands"
    case atr = "Average True Range"
    case standardDeviation = "Standard Deviation"
    case keltnerChannels = "Keltner Channels"
    case donchianChannels = "Donchian Channels"
    
    // Volume Indicators
    case obv = "On Balance Volume"
    case adl = "Accumulation/Distribution Line"
    case chaikinOsc = "Chaikin Oscillator"
    case vwap = "Volume Weighted Avg Price"
    case mfi = "Money Flow Index"
    
    // Pattern Recognition
    case ichimokuCloud = "Ichimoku Cloud"
    case parabolicSar = "Parabolic SAR"
    case zigzag = "ZigZag"
    case pivotPoints = "Pivot Points"
    
    var defaultPeriod: Int {
        switch self {
        case .sma, .ema, .wma, .dema, .tema: return 20
        case .rsi: return 14
        case .macd: return 26
        case .bollingerBands: return 20
        case .cci: return 20
        case .stochastic: return 14
        case .williamsR: return 14
        case .mfi: return 14
        case .roc: return 12
        case .ppo: return 26
        case .atr: return 14
        case .standardDeviation: return 20
        case .keltnerChannels: return 20
        case .donchianChannels: return 20
        case .trix: return 15
        case .ichimokuCloud: return 26
        case .parabolicSar: return 0 // Uses acceleration factor instead
        case .zigzag: return 5 // Percentage
        case .pivotPoints: return 0 // Uses daily data
        default: return 20
        }
    }
}

/// Represents a point on a technical indicator line
struct IndicatorPoint {
    let date: Date
    let value: Double
    var chartDataEntry: ChartDataEntry {
        ChartDataEntry(x: date.timeIntervalSince1970, y: value)
    }
}

/// Container for technical indicator data
struct IndicatorData {
    let type: IndicatorType
    let period: Int
    let points: [IndicatorPoint]
    let additionalData: [String: [IndicatorPoint]]
    
    init(type: IndicatorType, period: Int, points: [IndicatorPoint], additionalData: [String: [IndicatorPoint]] = [:]) {
        self.type = type
        self.period = period
        self.points = points
        self.additionalData = additionalData
    }
}

/// Technical Analysis Calculator
class TechnicalAnalysis {
    // MARK: - Moving Averages
    
    static func calculateSMA(prices: [Double], period: Int) -> [Double] {
        guard period > 0, !prices.isEmpty else { return [] }
        
        var sma: [Double] = []
        for i in 0..<prices.count {
            if i < period - 1 {
                sma.append(.nan)
                continue
            }
            
            let sum = prices[(i - period + 1)...i].reduce(0, +)
            sma.append(sum / Double(period))
        }
        return sma
    }
    
    static func calculateEMA(prices: [Double], period: Int) -> [Double] {
        guard period > 0, !prices.isEmpty else { return [] }
        
        let multiplier = 2.0 / Double(period + 1)
        var ema: [Double] = Array(repeating: .nan, count: prices.count)
        
        // First EMA is SMA
        if prices.count >= period {
            ema[period - 1] = prices[0..<period].reduce(0, +) / Double(period)
            
            // Calculate subsequent EMAs
            for i in period..<prices.count {
                ema[i] = (prices[i] - ema[i-1]) * multiplier + ema[i-1]
            }
        }
        
        return ema
    }
    
    static func calculateWMA(prices: [Double], period: Int) -> [Double] {
        guard period > 0, !prices.isEmpty else { return [] }
        
        var wma: [Double] = Array(repeating: .nan, count: prices.count)
        let weights = Array(1...period)
        let weightSum = weights.reduce(0, +)
        
        for i in (period - 1)..<prices.count {
            var sum = 0.0
            for j in 0..<period {
                sum += prices[i - j] * Double(weights[period - 1 - j])
            }
            wma[i] = sum / Double(weightSum)
        }
        return wma
    }
    
    static func calculateDEMA(prices: [Double], period: Int) -> [Double] {
        let ema1 = calculateEMA(prices: prices, period: period)
        let ema2 = calculateEMA(prices: ema1, period: period)
        
        return zip(ema1, ema2).map { 2 * $0 - $1 }
    }
    
    static func calculateTEMA(prices: [Double], period: Int) -> [Double] {
        let ema1 = calculateEMA(prices: prices, period: period)
        let ema2 = calculateEMA(prices: ema1, period: period)
        let ema3 = calculateEMA(prices: ema2, period: period)
        
        return zip(zip(ema1, ema2), ema3).map { 3 * $0.0 - 3 * $0.1 + $1 }
    }
    
    // MARK: - Momentum Indicators
    
    static func calculateRSI(prices: [Double], period: Int) -> [Double] {
        guard period > 0, prices.count > period else { return [] }
        
        var rsi: [Double] = Array(repeating: .nan, count: prices.count)
        var gains: [Double] = []
        var losses: [Double] = []
        
        // Calculate price changes
        for i in 1..<prices.count {
            let change = prices[i] - prices[i-1]
            gains.append(max(change, 0))
            losses.append(max(-change, 0))
        }
        
        // Calculate initial averages
        var avgGain = gains[0..<period].reduce(0, +) / Double(period)
        var avgLoss = losses[0..<period].reduce(0, +) / Double(period)
        
        // Calculate RSI for each point
        rsi[period] = 100 - (100 / (1 + avgGain/avgLoss))
        
        for i in (period + 1)..<prices.count {
            avgGain = (avgGain * Double(period - 1) + gains[i-1]) / Double(period)
            avgLoss = (avgLoss * Double(period - 1) + losses[i-1]) / Double(period)
            rsi[i] = 100 - (100 / (1 + avgGain/avgLoss))
        }
        
        return rsi
    }
    
    static func calculateMACD(prices: [Double], fastPeriod: Int = 12, slowPeriod: Int = 26, signalPeriod: Int = 9) -> (macd: [Double], signal: [Double], histogram: [Double]) {
        let fastEMA = calculateEMA(prices: prices, period: fastPeriod)
        let slowEMA = calculateEMA(prices: prices, period: slowPeriod)
        
        // Calculate MACD line
        var macd: [Double] = Array(repeating: .nan, count: prices.count)
        for i in 0..<prices.count {
            if !fastEMA[i].isNaN && !slowEMA[i].isNaN {
                macd[i] = fastEMA[i] - slowEMA[i]
            }
        }
        
        // Calculate Signal line (EMA of MACD)
        let signal = calculateEMA(prices: macd, period: signalPeriod)
        
        // Calculate Histogram
        var histogram: [Double] = Array(repeating: .nan, count: prices.count)
        for i in 0..<prices.count {
            if !macd[i].isNaN && !signal[i].isNaN {
                histogram[i] = macd[i] - signal[i]
            }
        }
        
        return (macd, signal, histogram)
    }
    
    static func calculateCCI(high: [Double], low: [Double], close: [Double], period: Int) -> [Double] {
        var cci: [Double] = Array(repeating: .nan, count: high.count)
        let typicalPrices = zip(zip(high, low), close).map { ($0.0 + $0.1 + $1) / 3.0 }
        
        for i in (period - 1)..<typicalPrices.count {
            let slice = Array(typicalPrices[(i - period + 1)...i])
            let sma = slice.reduce(0, +) / Double(period)
            let meanDeviation = slice.map { abs($0 - sma) }.reduce(0, +) / Double(period)
            cci[i] = (typicalPrices[i] - sma) / (0.015 * meanDeviation)
        }
        
        return cci
    }
    
    static func calculateStochastic(high: [Double], low: [Double], close: [Double], period: Int) -> (k: [Double], d: [Double]) {
        var k: [Double] = Array(repeating: .nan, count: close.count)
        
        for i in (period - 1)..<close.count {
            let slice = Array(close[(i - period + 1)...i])
            let highSlice = Array(high[(i - period + 1)...i])
            let lowSlice = Array(low[(i - period + 1)...i])
            
            let highest = highSlice.max() ?? 0
            let lowest = lowSlice.min() ?? 0
            
            k[i] = ((close[i] - lowest) / (highest - lowest)) * 100
        }
        
        let d = calculateSMA(prices: k, period: 3)
        return (k, d)
    }
    
    static func calculateWilliamsR(high: [Double], low: [Double], close: [Double], period: Int) -> [Double] {
        var r: [Double] = Array(repeating: .nan, count: close.count)
        
        for i in (period - 1)..<close.count {
            let highSlice = Array(high[(i - period + 1)...i])
            let lowSlice = Array(low[(i - period + 1)...i])
            
            let highest = highSlice.max() ?? 0
            let lowest = lowSlice.min() ?? 0
            
            r[i] = ((highest - close[i]) / (highest - lowest)) * -100
        }
        
        return r
    }
    
    // MARK: - Volume Indicators
    
    static func calculateOBV(close: [Double], volume: [Double]) -> [Double] {
        var obv: [Double] = Array(repeating: 0, count: close.count)
        
        for i in 1..<close.count {
            if close[i] > close[i-1] {
                obv[i] = obv[i-1] + volume[i]
            } else if close[i] < close[i-1] {
                obv[i] = obv[i-1] - volume[i]
            } else {
                obv[i] = obv[i-1]
            }
        }
        
        return obv
    }
    
    static func calculateVWAP(high: [Double], low: [Double], close: [Double], volume: [Double]) -> [Double] {
        var cumulativeTPV = 0.0 // Typical Price * Volume
        var cumulativeVolume = 0.0
        var vwap: [Double] = Array(repeating: .nan, count: close.count)
        
        for i in 0..<close.count {
            let typicalPrice = (high[i] + low[i] + close[i]) / 3.0
            cumulativeTPV += typicalPrice * volume[i]
            cumulativeVolume += volume[i]
            vwap[i] = cumulativeTPV / cumulativeVolume
        }
        
        return vwap
    }
    
    // MARK: - Pattern Recognition
    
    static func calculateIchimokuCloud(
        high: [Double],
        low: [Double],
        conversionPeriod: Int = 9,
        basePeriod: Int = 26,
        leadingSpanBPeriod: Int = 52,
        displacement: Int = 26
    ) -> (conversion: [Double], base: [Double], leadingSpanA: [Double], leadingSpanB: [Double]) {
        
        func calculateLine(_ period: Int) -> [Double] {
            var line: [Double] = Array(repeating: .nan, count: high.count)
            
            for i in (period - 1)..<high.count {
                let highSlice = Array(high[(i - period + 1)...i])
                let lowSlice = Array(low[(i - period + 1)...i])
                line[i] = (highSlice.max()! + lowSlice.min()!) / 2.0
            }
            
            return line
        }
        
        let conversion = calculateLine(conversionPeriod)
        let base = calculateLine(basePeriod)
        
        var leadingSpanA: [Double] = Array(repeating: .nan, count: high.count + displacement)
        var leadingSpanB: [Double] = Array(repeating: .nan, count: high.count + displacement)
        
        for i in 0..<high.count {
            if !conversion[i].isNaN && !base[i].isNaN {
                leadingSpanA[i + displacement] = (conversion[i] + base[i]) / 2.0
            }
        }
        
        let spanB = calculateLine(leadingSpanBPeriod)
        for i in 0..<high.count {
            if !spanB[i].isNaN {
                leadingSpanB[i + displacement] = spanB[i]
            }
        }
        
        return (conversion, base, leadingSpanA, leadingSpanB)
    }
    
    static func calculateParabolicSAR(
        high: [Double],
        low: [Double],
        accelerationFactor: Double = 0.02,
        maxAcceleration: Double = 0.2
    ) -> [Double] {
        var sar: [Double] = Array(repeating: .nan, count: high.count)
        var isUptrend = true
        var extremePoint = high[0]
        var acceleration = accelerationFactor
        
        sar[0] = low[0]
        
        for i in 1..<high.count {
            sar[i] = sar[i-1] + acceleration * (extremePoint - sar[i-1])
            
            if isUptrend {
                if low[i] < sar[i] {
                    isUptrend = false
                    sar[i] = extremePoint
                    extremePoint = low[i]
                    acceleration = accelerationFactor
                } else {
                    if high[i] > extremePoint {
                        extremePoint = high[i]
                        acceleration = min(acceleration + accelerationFactor, maxAcceleration)
                    }
                }
            } else {
                if high[i] > sar[i] {
                    isUptrend = true
                    sar[i] = extremePoint
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
    
    static func calculateZigZag(high: [Double], low: [Double], percentageChange: Double) -> [Double] {
        var zigzag: [Double] = Array(repeating: .nan, count: high.count)
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
                zigzag[j] = start.value + slope * Double(j - start.index)
            }
        }
        
        return zigzag
    }
    
    static func calculatePivotPoints(high: Double, low: Double, close: Double) -> (pp: Double, r1: Double, r2: Double, r3: Double, s1: Double, s2: Double, s3: Double) {
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
    
    static func calculateBollingerBands(prices: [Double], period: Int = 20, multiplier: Double = 2.0) -> (middle: [Double], upper: [Double], lower: [Double]) {
        let sma = calculateSMA(prices: prices, period: period)
        var upper: [Double] = Array(repeating: .nan, count: prices.count)
        var lower: [Double] = Array(repeating: .nan, count: prices.count)
        
        for i in (period - 1)..<prices.count {
            let slice = Array(prices[(i - period + 1)...i])
            let std = standardDeviation(slice)
            upper[i] = sma[i] + (multiplier * std)
            lower[i] = sma[i] - (multiplier * std)
        }
        
        return (sma, upper, lower)
    }
    
    static func calculateATR(high: [Double], low: [Double], close: [Double], period: Int) -> [Double] {
        var atr: [Double] = Array(repeating: .nan, count: high.count)
        
        for i in (period - 1)..<high.count {
            let highLow = zip(high, low).map { $0 - $1 }
            let highClose = zip(high, close).map { abs($0 - $1) }
            let lowClose = zip(low, close).map { abs($0 - $1) }
            let tr = zip(highLow, zip(highClose, lowClose)).map { max($0, max($1.0, $1.1)) }
            atr[i] = tr.reduce(0, +) / Double(period)
        }
        
        return atr
    }
    
    static func calculateStandardDeviation(prices: [Double], period: Int) -> [Double] {
        var std: [Double] = Array(repeating: .nan, count: prices.count)
        
        for i in (period - 1)..<prices.count {
            let slice = Array(prices[(i - period + 1)...i])
            std[i] = standardDeviation(slice)
        }
        
        return std
    }
    
    static func calculateKeltnerChannels(high: [Double], low: [Double], close: [Double], period: Int, multiplier: Double) -> (middle: [Double], upper: [Double], lower: [Double]) {
        let ema = calculateEMA(prices: close, period: period)
        let atr = calculateATR(high: high, low: low, close: close, period: period)
        
        var upper: [Double] = Array(repeating: .nan, count: close.count)
        var lower: [Double] = Array(repeating: .nan, count: close.count)
        
        for i in (period - 1)..<close.count {
            upper[i] = ema[i] + (multiplier * atr[i])
            lower[i] = ema[i] - (multiplier * atr[i])
        }
        
        return (ema, upper, lower)
    }
    
    static func calculateDonchianChannels(high: [Double], low: [Double], period: Int) -> (middle: [Double], upper: [Double], lower: [Double]) {
        var upper: [Double] = Array(repeating: .nan, count: high.count)
        var lower: [Double] = Array(repeating: .nan, count: high.count)
        
        for i in (period - 1)..<high.count {
            let highSlice = Array(high[(i - period + 1)...i])
            let lowSlice = Array(low[(i - period + 1)...i])
            upper[i] = highSlice.max() ?? 0
            lower[i] = lowSlice.min() ?? 0
        }
        
        return ([], upper, lower)
    }
    
    // MARK: - Helper Functions
    
    private static func standardDeviation(_ values: [Double]) -> Double {
        let mean = values.reduce(0, +) / Double(values.count)
        let sumSquared = values.map { pow($0 - mean, 2) }.reduce(0, +)
        return sqrt(sumSquared / Double(values.count))
    }
}
