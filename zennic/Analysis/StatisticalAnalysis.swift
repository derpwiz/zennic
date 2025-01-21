import Foundation

/// Statistical analysis tools for market data
class StatisticalAnalysis {
    // MARK: - Descriptive Statistics
    
    struct DescriptiveStats {
        let mean: Double
        let median: Double
        let mode: Double?
        let standardDeviation: Double
        let variance: Double
        let skewness: Double
        let kurtosis: Double
        let min: Double
        let max: Double
        let range: Double
        let quartiles: (q1: Double, q2: Double, q3: Double)
        let iqr: Double
    }
    
    static func calculateDescriptiveStats(_ data: [Double]) -> DescriptiveStats {
        let sortedData = data.sorted()
        let n = Double(data.count)
        
        // Basic statistics
        let mean = data.reduce(0, +) / n
        let median = calculateMedian(sortedData)
        let mode = calculateMode(data)
        let variance = calculateVariance(data, mean: mean)
        let standardDeviation = sqrt(variance)
        
        // Higher moments
        let skewness = calculateSkewness(data, mean: mean, standardDeviation: standardDeviation)
        let kurtosis = calculateKurtosis(data, mean: mean, standardDeviation: standardDeviation)
        
        // Range statistics
        let min = sortedData.first ?? 0
        let max = sortedData.last ?? 0
        let range = max - min
        
        // Quartiles
        let quartiles = calculateQuartiles(sortedData)
        let iqr = quartiles.q3 - quartiles.q1
        
        return DescriptiveStats(
            mean: mean,
            median: median,
            mode: mode,
            standardDeviation: standardDeviation,
            variance: variance,
            skewness: skewness,
            kurtosis: kurtosis,
            min: min,
            max: max,
            range: range,
            quartiles: quartiles,
            iqr: iqr
        )
    }
    
    // MARK: - Time Series Analysis
    
    struct TimeSeriesStats {
        let trend: TrendAnalysis
        let seasonality: SeasonalityAnalysis
        let stationarity: StationarityTest
        let autocorrelation: [Double]
        let volatility: VolatilityAnalysis
    }
    
    struct TrendAnalysis {
        let slope: Double
        let intercept: Double
        let rSquared: Double
        let trendType: TrendType
    }
    
    enum TrendType {
        case linear
        case exponential
        case logarithmic
        case polynomial(degree: Int)
    }
    
    struct SeasonalityAnalysis {
        let seasonalityPresent: Bool
        let period: Int?
        let seasonalFactors: [Double]?
        let strength: Double
    }
    
    struct StationarityTest {
        let isStationary: Bool
        let adfStatistic: Double
        let pValue: Double
        let criticalValues: [String: Double]
    }
    
    struct VolatilityAnalysis {
        let historicalVolatility: Double
        let impliedVolatility: Double?
        let volatilityClusters: [(start: Int, end: Int)]
        let garchParameters: GARCHParameters?
    }
    
    struct GARCHParameters {
        let omega: Double
        let alpha: Double
        let beta: Double
        let persistence: Double
    }
    
    static func analyzeTimeSeries(_ prices: [Double], period: Int = 0) -> TimeSeriesStats {
        // Trend Analysis
        let trend = analyzeTrend(prices)
        
        // Seasonality Analysis
        let seasonality = analyzeSeasonality(prices, period: period)
        
        // Stationarity Test
        let stationarity = testStationarity(prices)
        
        // Autocorrelation
        let autocorrelation = calculateAutocorrelation(prices, lags: 20)
        
        // Volatility Analysis
        let volatility = analyzeVolatility(prices)
        
        return TimeSeriesStats(
            trend: trend,
            seasonality: seasonality,
            stationarity: stationarity,
            autocorrelation: autocorrelation,
            volatility: volatility
        )
    }
    
    // MARK: - Market Efficiency Tests
    
    struct MarketEfficiencyTests {
        let hurst: Double
        let varianceRatio: Double
        let runTest: RunTestResult
        let ljungBox: LjungBoxTest
    }
    
    struct RunTestResult {
        let isRandom: Bool
        let zScore: Double
        let pValue: Double
    }
    
    struct LjungBoxTest {
        let statistic: Double
        let pValue: Double
        let degreesOfFreedom: Int
    }
    
    static func testMarketEfficiency(_ prices: [Double]) -> MarketEfficiencyTests {
        let hurst = calculateHurstExponent(prices)
        let varianceRatio = calculateVarianceRatio(prices)
        let runTest = performRunTest(prices)
        let ljungBox = performLjungBoxTest(prices)
        
        return MarketEfficiencyTests(
            hurst: hurst,
            varianceRatio: varianceRatio,
            runTest: runTest,
            ljungBox: ljungBox
        )
    }
    
    // MARK: - Distribution Analysis
    
    struct DistributionAnalysis {
        let normalityTest: NormalityTest
        let tailAnalysis: TailAnalysis
        let distributionFit: DistributionFit
    }
    
    struct NormalityTest {
        let isNormal: Bool
        let jarqueBera: Double
        let shapiroWilk: Double
        let pValue: Double
    }
    
    struct TailAnalysis {
        let leftTailIndex: Double
        let rightTailIndex: Double
        let extremeValueDistribution: String
    }
    
    struct DistributionFit {
        let bestFit: String
        let parameters: [String: Double]
        let goodnessOfFit: Double
    }
    
    static func analyzeDistribution(_ returns: [Double]) -> DistributionAnalysis {
        let normalityTest = testNormality(returns)
        let tailAnalysis = analyzeTails(returns)
        let distributionFit = fitDistribution(returns)
        
        return DistributionAnalysis(
            normalityTest: normalityTest,
            tailAnalysis: tailAnalysis,
            distributionFit: distributionFit
        )
    }
    
    // MARK: - Helper Methods
    
    private static func calculateMedian(_ sortedData: [Double]) -> Double {
        let count = sortedData.count
        if count % 2 == 0 {
            return (sortedData[count/2 - 1] + sortedData[count/2]) / 2
        } else {
            return sortedData[count/2]
        }
    }
    
    private static func calculateMode(_ data: [Double]) -> Double? {
        var frequencies: [Double: Int] = [:]
        data.forEach { frequencies[$0, default: 0] += 1 }
        return frequencies.max(by: { $0.value < $1.value })?.key
    }
    
    private static func calculateVariance(_ data: [Double], mean: Double) -> Double {
        let n = Double(data.count)
        let sumSquaredDiff = data.reduce(0) { $0 + pow($1 - mean, 2) }
        return sumSquaredDiff / (n - 1)
    }
    
    private static func calculateSkewness(_ data: [Double], mean: Double, standardDeviation: Double) -> Double {
        let n = Double(data.count)
        let cubedDiffs = data.map { pow(($0 - mean) / standardDeviation, 3) }
        return (n * cubedDiffs.reduce(0, +)) / ((n - 1) * (n - 2))
    }
    
    private static func calculateKurtosis(_ data: [Double], mean: Double, standardDeviation: Double) -> Double {
        let n = Double(data.count)
        let fourthMoment = data.map { pow(($0 - mean) / standardDeviation, 4) }.reduce(0, +)
        return (n * (n + 1) * fourthMoment) / ((n - 1) * (n - 2) * (n - 3)) - (3 * pow(n - 1, 2)) / ((n - 2) * (n - 3))
    }
    
    private static func calculateQuartiles(_ sortedData: [Double]) -> (q1: Double, q2: Double, q3: Double) {
        let count = sortedData.count
        let q2 = calculateMedian(sortedData)
        
        let lowerHalf = Array(sortedData[0..<count/2])
        let upperHalf = Array(sortedData[(count + 1)/2..<count])
        
        let q1 = calculateMedian(lowerHalf)
        let q3 = calculateMedian(upperHalf)
        
        return (q1, q2, q3)
    }
    
    private static func calculateAutocorrelation(_ data: [Double], lags: Int) -> [Double] {
        let mean = data.reduce(0, +) / Double(data.count)
        let variance = calculateVariance(data, mean: mean)
        
        return (0...lags).map { lag in
            var sum = 0.0
            for i in lag..<data.count {
                sum += (data[i] - mean) * (data[i - lag] - mean)
            }
            return sum / (Double(data.count - lag) * variance)
        }
    }
    
    private static func calculateHurstExponent(_ prices: [Double]) -> Double {
        // Implement Hurst exponent calculation
        // This involves calculating (R/S) analysis over different time periods
        return 0.5 // Placeholder
    }
    
    private static func calculateVarianceRatio(_ prices: [Double]) -> Double {
        // Implement variance ratio test
        // Compare variances of returns at different frequencies
        return 1.0 // Placeholder
    }
    
    private static func performRunTest(_ prices: [Double]) -> RunTestResult {
        // Implement runs test for randomness
        return RunTestResult(isRandom: true, zScore: 0, pValue: 0.5) // Placeholder
    }
    
    private static func performLjungBoxTest(_ prices: [Double]) -> LjungBoxTest {
        // Implement Ljung-Box test for autocorrelation
        return LjungBoxTest(statistic: 0, pValue: 0.5, degreesOfFreedom: 10) // Placeholder
    }
    
    private static func testNormality(_ returns: [Double]) -> NormalityTest {
        // Implement normality tests
        return NormalityTest(isNormal: false, jarqueBera: 0, shapiroWilk: 0, pValue: 0.5) // Placeholder
    }
    
    private static func analyzeTails(_ returns: [Double]) -> TailAnalysis {
        // Implement tail analysis
        return TailAnalysis(leftTailIndex: 0, rightTailIndex: 0, extremeValueDistribution: "Generalized Pareto") // Placeholder
    }
    
    private static func fitDistribution(_ returns: [Double]) -> DistributionFit {
        // Implement distribution fitting
        return DistributionFit(bestFit: "Normal", parameters: [:], goodnessOfFit: 0) // Placeholder
    }
    
    private static func analyzeTrend(_ prices: [Double]) -> TrendAnalysis {
        // Implement trend analysis
        return TrendAnalysis(slope: 0, intercept: 0, rSquared: 0, trendType: .linear) // Placeholder
    }
    
    private static func analyzeSeasonality(_ prices: [Double], period: Int) -> SeasonalityAnalysis {
        // Implement seasonality analysis
        return SeasonalityAnalysis(seasonalityPresent: false, period: nil, seasonalFactors: nil, strength: 0) // Placeholder
    }
    
    private static func testStationarity(_ prices: [Double]) -> StationarityTest {
        // Implement stationarity test
        return StationarityTest(isStationary: false, adfStatistic: 0, pValue: 0.5, criticalValues: [:]) // Placeholder
    }
    
    private static func analyzeVolatility(_ prices: [Double]) -> VolatilityAnalysis {
        // Implement volatility analysis
        return VolatilityAnalysis(historicalVolatility: 0, impliedVolatility: nil, volatilityClusters: [], garchParameters: nil) // Placeholder
    }
}
