import Foundation
import Combine

@MainActor
final class ChartingViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published private(set) var chartData: [StockBarData] = []
    @Published private(set) var isLoading = false
    @Published private(set) var error: Error?
    @Published var selectedSymbol: String = "AAPL" {
        didSet {
            if !selectedSymbol.isEmpty {
                clearError()
                refreshChartData()
            }
        }
    }
    @Published var selectedTimeframe: String = "1Day" {
        didSet {
            if isValidTimeframe(selectedTimeframe) {
                clearError()
                refreshChartData()
            }
        }
    }
    @Published var selectedIndicators: Set<IndicatorType> = [] {
        didSet {
            refreshIndicators()
        }
    }
    @Published private(set) var calculatedIndicators: [IndicatorType: [Double]] = [:]
    @Published private(set) var isCalculatingIndicators = false
    
    // MARK: - Private Properties
    
    private let marketDataService: MarketDataService
    private var cancellables = Set<AnyCancellable>()
    private let calculationQueue = DispatchQueue(label: "com.zennic.chartingCalculations", qos: .userInitiated)
    private let maxDataPoints = 1000
    
    // Improved cache management using NSCache
    private let calculationCache: NSCache<NSString, NSArray> = {
        let cache = NSCache<NSString, NSArray>()
        cache.countLimit = 100 // Limit number of cached items
        cache.totalCostLimit = 50 * 1024 * 1024 // 50MB limit
        return cache
    }()
    
    private var dataTask: Task<Void, Never>?
    private var calculationTask: Task<Void, Never>?
    @MainActor private var calculationTasks: Set<Task<[Double], Never>> = []
    
    // MARK: - Initialization
    
    init(marketDataService: MarketDataService = MarketDataService.shared) {
        self.marketDataService = marketDataService
        refreshChartData()
    }
    
    deinit {
        cancellables.removeAll()
        dataTask?.cancel()
        calculationTask?.cancel()
        calculationTasks.forEach { $0.cancel() }
        calculationTasks.removeAll()
        calculationCache.removeAllObjects()
    }
    
    // MARK: - Private Methods
    
    private func refreshChartData() {
        dataTask?.cancel()
        dataTask = Task { [symbol = selectedSymbol, timeframe = selectedTimeframe] in
            await fetchChartData(symbol: symbol, timeframe: timeframe)
        }
    }
    
    private func refreshIndicators() {
        calculationTask?.cancel()
        calculationTask = Task { [data = chartData, indicators = selectedIndicators] in
            await recalculateIndicators(data: data, indicators: indicators)
        }
    }
    
    private func isValidTimeframe(_ timeframe: String) -> Bool {
        return ["1Day", "1Hour", "5Min", "1Min"].contains(timeframe)
    }
    
    private func clearError() {
        error = nil
    }
    
    @MainActor
    private func addCalculationTask(_ task: Task<[Double], Never>) {
        calculationTasks.insert(task)
    }
    
    @MainActor
    private func removeCalculationTask(_ task: Task<[Double], Never>) {
        calculationTasks.remove(task)
    }
    
    private func getCachedValue(for key: String) -> [Double]? {
        calculationCache.object(forKey: key as NSString)?.map { $0 as! Double }
    }
    
    private func setCachedValue(_ value: [Double], for key: String) {
        calculationCache.setObject(value as NSArray, forKey: key as NSString, cost: value.count * 8)
    }
    
    // MARK: - Public Methods
    
    /// Fetches chart data for the specified symbol and timeframe
    func fetchChartData(symbol: String, timeframe: String) async {
        guard !symbol.isEmpty && isValidTimeframe(timeframe) else {
            self.error = ChartError.invalidParameters
            return
        }
        
        isLoading = true
        error = nil
        
        do {
            var data = try await marketDataService.fetchBarData(symbol: symbol, timeframe: timeframe)
            
            // Limit the number of data points to prevent performance issues
            if data.count > maxDataPoints {
                data = Array(data.suffix(maxDataPoints))
            }
            
            self.chartData = data
            calculationCache.removeAllObjects() // Clear cache when new data is fetched
            refreshIndicators()
        } catch {
            self.error = ChartError.fetchFailed(error)
        }
        
        isLoading = false
    }
    
    /// Adds a technical indicator to the chart
    func addIndicator(_ indicator: IndicatorType) {
        guard validateIndicator(indicator) else {
            error = ChartError.invalidIndicator
            return
        }
        
        selectedIndicators.insert(indicator)
    }
    
    /// Removes a technical indicator from the chart
    func removeIndicator(_ indicator: IndicatorType) {
        selectedIndicators.remove(indicator)
        calculatedIndicators.removeValue(forKey: indicator)
    }
    
    // MARK: - Private Methods
    
    private func validateIndicator(_ indicator: IndicatorType) -> Bool {
        switch indicator {
        case .sma(let period), .ema(let period), .rsi(let period):
            return period > 0 && period < chartData.count
        case .macd(let fast, let slow, let signal):
            return fast > 0 && slow > fast && signal > 0 && slow < chartData.count
        }
    }
    
    private func recalculateIndicators(data: [StockBarData], indicators: Set<IndicatorType>) async {
        guard !data.isEmpty else { return }
        
        isCalculatingIndicators = true
        defer { isCalculatingIndicators = false }
        
        var newCalculations: [IndicatorType: [Double]] = [:]
        
        await withTaskGroup(of: (IndicatorType, [Double]).self) { group in
            for indicator in indicators {
                group.addTask { [weak self] in
                    guard let self = self else { return (indicator, []) }
                    let values = await self.calculateIndicator(indicator, for: data)
                    return (indicator, values)
                }
            }
            
            for await (indicator, values) in group {
                newCalculations[indicator] = values
            }
        }
        
        calculatedIndicators = newCalculations
    }
    
    private func calculateIndicator(_ indicator: IndicatorType, for data: [StockBarData]) async -> [Double] {
        // Check cache first
        let cacheKey = "\(indicator)_\(data.count)"
        if let cached = getCachedValue(for: cacheKey) {
            return cached
        }
        
        let calculationTask = Task<[Double], Never> {
            let values: [Double]
            
            switch indicator {
            case .sma(let period):
                values = calculateSMA(data: data, period: period)
            case .ema(let period):
                values = calculateEMA(data: data, period: period)
            case .rsi(let period):
                values = calculateRSI(data: data, period: period)
            case .macd(let fastPeriod, let slowPeriod, let signalPeriod):
                values = calculateMACD(data: data, fastPeriod: fastPeriod, slowPeriod: slowPeriod, signalPeriod: signalPeriod)
            }
            
            // Cache the result if task wasn't cancelled
            if !Task.isCancelled {
                setCachedValue(values, for: cacheKey)
            }
            
            return values
        }
        
        // Track the calculation task
        addCalculationTask(calculationTask)
        let result = await calculationTask.value
        removeCalculationTask(calculationTask)
        
        return result
    }
    
    private func calculateSMA(data: [StockBarData], period: Int) -> [Double] {
        guard period > 0, !data.isEmpty, period < data.count else { return [] }
        
        let prices = data.map { $0.closePrice }
        var sma = [Double](repeating: 0, count: data.count)
        var sum = prices[0..<period].reduce(0, +)
        
        sma[period - 1] = sum / Double(period)
        
        for i in period..<prices.count {
            sum = sum - prices[i - period] + prices[i]
            sma[i] = sum / Double(period)
        }
        
        return sma
    }
    
    private func calculateEMA(data: [StockBarData], period: Int) -> [Double] {
        guard period > 0, !data.isEmpty, period < data.count else { return [] }
        
        let prices = data.map { $0.closePrice }
        var ema = [Double](repeating: 0, count: data.count)
        let multiplier = 2.0 / Double(period + 1)
        
        // Initialize EMA with SMA for the first period
        ema[period - 1] = prices[0..<period].reduce(0, +) / Double(period)
        
        for i in period..<prices.count {
            ema[i] = (prices[i] - ema[i-1]) * multiplier + ema[i-1]
        }
        
        return ema
    }
    
    private func calculateRSI(data: [StockBarData], period: Int) -> [Double] {
        guard period > 0, data.count > period else { return [] }
        
        let prices = data.map { $0.closePrice }
        var rsi = [Double](repeating: 0, count: data.count)
        var gains = [Double]()
        var losses = [Double]()
        
        // Calculate price changes
        for i in 1..<prices.count {
            let change = prices[i] - prices[i-1]
            gains.append(max(change, 0))
            losses.append(max(-change, 0))
        }
        
        // Calculate initial averages
        var avgGain = gains[..<period].reduce(0, +) / Double(period)
        var avgLoss = losses[..<period].reduce(0, +) / Double(period)
        
        // Calculate RSI values
        rsi[period] = 100 - (100 / (1 + avgGain/max(avgLoss, .ulpOfOne)))
        
        for i in (period + 1)..<data.count {
            avgGain = (avgGain * Double(period - 1) + gains[i-1]) / Double(period)
            avgLoss = (avgLoss * Double(period - 1) + losses[i-1]) / Double(period)
            rsi[i] = 100 - (100 / (1 + avgGain/max(avgLoss, .ulpOfOne)))
        }
        
        return rsi
    }
    
    private func calculateMACD(data: [StockBarData], fastPeriod: Int, slowPeriod: Int, signalPeriod: Int) -> [Double] {
        guard !data.isEmpty, slowPeriod > fastPeriod, fastPeriod > 0, signalPeriod > 0 else { return [] }
        
        let fastEMA = calculateEMA(data: data, period: fastPeriod)
        let slowEMA = calculateEMA(data: data, period: slowPeriod)
        var macd = [Double](repeating: 0, count: data.count)
        
        // Calculate MACD line
        for i in slowPeriod..<data.count {
            macd[i] = fastEMA[i] - slowEMA[i]
        }
        
        // Calculate Signal line (EMA of MACD)
        var signal = [Double](repeating: 0, count: data.count)
        let multiplier = 2.0 / Double(signalPeriod + 1)
        
        // Initialize signal with SMA of MACD
        let startIndex = slowPeriod + signalPeriod - 1
        signal[startIndex] = macd[startIndex-signalPeriod+1...startIndex].reduce(0, +) / Double(signalPeriod)
        
        for i in (startIndex + 1)..<data.count {
            signal[i] = (macd[i] - signal[i-1]) * multiplier + signal[i-1]
        }
        
        // Return MACD histogram (MACD - Signal)
        return zip(macd, signal).map { $0 - $1 }
    }
}

// MARK: - Error Types

enum ChartError: LocalizedError {
    case invalidParameters
    case invalidIndicator
    case fetchFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidParameters:
            return "Invalid symbol or timeframe"
        case .invalidIndicator:
            return "Invalid indicator parameters"
        case .fetchFailed(let error):
            return "Failed to fetch chart data: \(error.localizedDescription)"
        }
    }
}
