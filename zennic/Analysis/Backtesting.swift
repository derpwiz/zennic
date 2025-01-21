import Foundation

/// Backtesting engine for trading strategies
class Backtesting {
    // MARK: - Types
    
    enum OrderType {
        case market
        case limit(price: Double)
        case stop(price: Double)
        case stopLimit(stopPrice: Double, limitPrice: Double)
    }
    
    enum OrderSide {
        case buy
        case sell
    }
    
    enum PositionType {
        case long
        case short
    }
    
    struct Order {
        let symbol: String
        let type: OrderType
        let side: OrderSide
        let quantity: Double
        let timestamp: Date
        var fillPrice: Double?
        var fillTime: Date?
        var status: OrderStatus
        let stopLoss: Double?
        let takeProfit: Double?
    }
    
    enum OrderStatus {
        case pending
        case filled
        case cancelled
        case rejected
    }
    
    struct Position {
        let symbol: String
        let type: PositionType
        let entryPrice: Double
        let quantity: Double
        let entryTime: Date
        var exitPrice: Double?
        var exitTime: Date?
        var pnl: Double?
    }
    
    struct Trade {
        let position: Position
        let entryOrder: Order
        let exitOrder: Order?
        let pnl: Double
        let returnPercent: Double
        let holdingPeriod: TimeInterval
    }
    
    struct BacktestResult {
        // Performance Metrics
        let totalReturn: Double
        let annualizedReturn: Double
        let sharpeRatio: Double
        let sortinoRatio: Double
        let maxDrawdown: Double
        let maxDrawdownDuration: TimeInterval
        let winRate: Double
        let profitFactor: Double
        let calmarRatio: Double
        
        // Risk Metrics
        let volatility: Double
        let beta: Double
        let alpha: Double
        let informationRatio: Double
        let varFivePercent: Double
        let expectedShortfall: Double
        
        // Trade Statistics
        let totalTrades: Int
        let winningTrades: Int
        let losingTrades: Int
        let averageWin: Double
        let averageLoss: Double
        let largestWin: Double
        let largestLoss: Double
        let averageHoldingPeriod: TimeInterval
        
        // Detailed Results
        let equityCurve: [Double]
        let drawdownCurve: [Double]
        let monthlyReturns: [Double]
        let trades: [Trade]
    }
    
    // MARK: - Strategy Protocol
    
    protocol TradingStrategy {
        func initialize(data: MarketData)
        func onBar(data: MarketData) -> [Order]
        func onTrade(trade: Trade)
        func onOrderFilled(order: Order)
    }
    
    // MARK: - Market Data
    
    struct MarketData {
        let timestamp: Date
        let symbol: String
        let open: Double
        let high: Double
        let low: Double
        let close: Double
        let volume: Double
        let indicators: [String: Double]
        let patterns: [PatternRecognition.PatternMatch]
    }
    
    // MARK: - Backtesting Engine
    
    private var data: [MarketData] = []
    private var strategy: TradingStrategy
    private var positions: [String: Position] = [:]
    private var orders: [Order] = []
    private var trades: [Trade] = []
    private var cash: Double
    private var equity: [Double] = []
    
    init(strategy: TradingStrategy, initialCash: Double = 100000) {
        self.strategy = strategy
        self.cash = initialCash
    }
    
    func run(data: [MarketData], commission: Double = 0.001) -> BacktestResult {
        self.data = data
        equity = [cash]
        strategy.initialize(data: data[0])
        
        for (i, bar) in data.enumerated() {
            // Process pending orders
            processOrders(at: i)
            
            // Get new orders from strategy
            let newOrders = strategy.onBar(data: bar)
            orders.append(contentsOf: newOrders)
            
            // Update positions and equity
            updatePositions(at: i)
            equity.append(calculateEquity(at: i))
        }
        
        return calculateResults()
    }
    
    // MARK: - Private Methods
    
    private func processOrders(at index: Int) {
        let bar = data[index]
        
        for order in orders where order.status == .pending {
            switch order.type {
            case .market:
                fillOrder(order, at: bar.close, timestamp: bar.timestamp)
                
            case .limit(let price):
                if order.side == .buy && bar.low <= price {
                    fillOrder(order, at: price, timestamp: bar.timestamp)
                } else if order.side == .sell && bar.high >= price {
                    fillOrder(order, at: price, timestamp: bar.timestamp)
                }
                
            case .stop(let price):
                if order.side == .buy && bar.high >= price {
                    fillOrder(order, at: price, timestamp: bar.timestamp)
                } else if order.side == .sell && bar.low <= price {
                    fillOrder(order, at: price, timestamp: bar.timestamp)
                }
                
            case .stopLimit(let stopPrice, let limitPrice):
                if order.side == .buy && bar.high >= stopPrice && bar.low <= limitPrice {
                    fillOrder(order, at: limitPrice, timestamp: bar.timestamp)
                } else if order.side == .sell && bar.low <= stopPrice && bar.high >= limitPrice {
                    fillOrder(order, at: limitPrice, timestamp: bar.timestamp)
                }
            }
        }
    }
    
    private func fillOrder(_ order: Order, at price: Double, timestamp: Date) {
        var filledOrder = order
        filledOrder.fillPrice = price
        filledOrder.fillTime = timestamp
        filledOrder.status = .filled
        
        // Update cash
        let cost = price * order.quantity
        cash -= cost
        
        // Create or update position
        if let existingPosition = positions[order.symbol] {
            if order.side == .sell {
                // Close position
                let pnl = (price - existingPosition.entryPrice) * existingPosition.quantity
                let trade = Trade(
                    position: existingPosition,
                    entryOrder: order,
                    exitOrder: filledOrder,
                    pnl: pnl,
                    returnPercent: pnl / (existingPosition.entryPrice * existingPosition.quantity),
                    holdingPeriod: timestamp.timeIntervalSince(existingPosition.entryTime)
                )
                trades.append(trade)
                positions.removeValue(forKey: order.symbol)
                strategy.onTrade(trade: trade)
            }
        } else if order.side == .buy {
            // Open new position
            let position = Position(
                symbol: order.symbol,
                type: .long,
                entryPrice: price,
                quantity: order.quantity,
                entryTime: timestamp,
                exitPrice: nil,
                exitTime: nil,
                pnl: nil
            )
            positions[order.symbol] = position
        }
        
        strategy.onOrderFilled(order: filledOrder)
    }
    
    private func updatePositions(at index: Int) {
        let bar = data[index]
        
        for (symbol, position) in positions {
            // Check stop loss and take profit
            if let order = orders.first(where: { $0.symbol == symbol && $0.status == .pending }) {
                if let stopLoss = order.stopLoss, bar.low <= stopLoss {
                    let exitOrder = Order(
                        symbol: symbol,
                        type: .stop(price: stopLoss),
                        side: .sell,
                        quantity: position.quantity,
                        timestamp: bar.timestamp,
                        fillPrice: nil,
                        fillTime: nil,
                        status: .pending,
                        stopLoss: nil,
                        takeProfit: nil
                    )
                    orders.append(exitOrder)
                }
                
                if let takeProfit = order.takeProfit, bar.high >= takeProfit {
                    let exitOrder = Order(
                        symbol: symbol,
                        type: .limit(price: takeProfit),
                        side: .sell,
                        quantity: position.quantity,
                        timestamp: bar.timestamp,
                        fillPrice: nil,
                        fillTime: nil,
                        status: .pending,
                        stopLoss: nil,
                        takeProfit: nil
                    )
                    orders.append(exitOrder)
                }
            }
        }
    }
    
    private func calculateEquity(at index: Int) -> Double {
        let bar = data[index]
        let positionsValue = positions.values.reduce(0.0) { total, position in
            total + (position.quantity * bar.close)
        }
        return cash + positionsValue
    }
    
    private func calculateResults() -> BacktestResult {
        let returns = calculateReturns()
        let drawdowns = calculateDrawdowns()
        
        return BacktestResult(
            totalReturn: (equity.last! - equity.first!) / equity.first!,
            annualizedReturn: calculateAnnualizedReturn(),
            sharpeRatio: calculateSharpeRatio(returns),
            sortinoRatio: calculateSortinoRatio(returns),
            maxDrawdown: drawdowns.max() ?? 0,
            maxDrawdownDuration: calculateMaxDrawdownDuration(),
            winRate: Double(trades.filter { $0.pnl > 0 }.count) / Double(trades.count),
            profitFactor: calculateProfitFactor(),
            calmarRatio: calculateCalmarRatio(),
            volatility: calculateVolatility(returns),
            beta: calculateBeta(returns),
            alpha: calculateAlpha(returns),
            informationRatio: calculateInformationRatio(returns),
            varFivePercent: calculateVaR(returns, percentile: 0.05),
            expectedShortfall: calculateExpectedShortfall(returns, percentile: 0.05),
            totalTrades: trades.count,
            winningTrades: trades.filter { $0.pnl > 0 }.count,
            losingTrades: trades.filter { $0.pnl < 0 }.count,
            averageWin: trades.filter { $0.pnl > 0 }.map { $0.pnl }.reduce(0, +) / Double(trades.filter { $0.pnl > 0 }.count),
            averageLoss: trades.filter { $0.pnl < 0 }.map { $0.pnl }.reduce(0, +) / Double(trades.filter { $0.pnl < 0 }.count),
            largestWin: trades.map { $0.pnl }.max() ?? 0,
            largestLoss: trades.map { $0.pnl }.min() ?? 0,
            averageHoldingPeriod: trades.map { $0.holdingPeriod }.reduce(0, +) / Double(trades.count),
            equityCurve: equity,
            drawdownCurve: drawdowns,
            monthlyReturns: calculateMonthlyReturns(),
            trades: trades
        )
    }
    
    private func calculateReturns() -> [Double] {
        var returns: [Double] = []
        for i in 1..<equity.count {
            returns.append((equity[i] - equity[i-1]) / equity[i-1])
        }
        return returns
    }
    
    private func calculateDrawdowns() -> [Double] {
        var drawdowns: [Double] = []
        var peak = equity[0]
        
        for value in equity {
            if value > peak {
                peak = value
            }
            let drawdown = (peak - value) / peak
            drawdowns.append(drawdown)
        }
        
        return drawdowns
    }
    
    // Add implementations for other calculation methods...
    private func calculateAnnualizedReturn() -> Double {
        // Placeholder
        return 0.0
    }
    
    private func calculateSharpeRatio(_ returns: [Double]) -> Double {
        // Placeholder
        return 0.0
    }
    
    private func calculateSortinoRatio(_ returns: [Double]) -> Double {
        // Placeholder
        return 0.0
    }
    
    private func calculateMaxDrawdownDuration() -> TimeInterval {
        // Placeholder
        return 0.0
    }
    
    private func calculateProfitFactor() -> Double {
        // Placeholder
        return 0.0
    }
    
    private func calculateCalmarRatio() -> Double {
        // Placeholder
        return 0.0
    }
    
    private func calculateVolatility(_ returns: [Double]) -> Double {
        // Placeholder
        return 0.0
    }
    
    private func calculateBeta(_ returns: [Double]) -> Double {
        // Placeholder
        return 0.0
    }
    
    private func calculateAlpha(_ returns: [Double]) -> Double {
        // Placeholder
        return 0.0
    }
    
    private func calculateInformationRatio(_ returns: [Double]) -> Double {
        // Placeholder
        return 0.0
    }
    
    private func calculateVaR(_ returns: [Double], percentile: Double) -> Double {
        // Placeholder
        return 0.0
    }
    
    private func calculateExpectedShortfall(_ returns: [Double], percentile: Double) -> Double {
        // Placeholder
        return 0.0
    }
    
    private func calculateMonthlyReturns() -> [Double] {
        // Placeholder
        return []
    }
}
