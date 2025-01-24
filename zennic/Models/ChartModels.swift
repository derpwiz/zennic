import Foundation
import SwiftUI

/// Chart annotation model for marking significant points
struct ChartAnnotation: Identifiable, Hashable {
    // MARK: - Properties
    
    let id = UUID()
    let type: AnnotationType
    let date: Date
    let price: Double
    let text: String
    
    /// Converts to chart data entry format
    var chartDataEntry: (x: TimeInterval, y: Double) {
        (date.timeIntervalSince1970, price)
    }
    
    // MARK: - Hashable
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: ChartAnnotation, rhs: ChartAnnotation) -> Bool {
        lhs.id == rhs.id &&
        lhs.type == rhs.type &&
        lhs.date == rhs.date &&
        abs(lhs.price - rhs.price) < .ulpOfOne &&
        lhs.text == rhs.text
    }
}

/// Types of chart annotations
enum AnnotationType: String, CaseIterable, Hashable {
    case note = "Note"
    case support = "Support"
    case resistance = "Resistance"
    case trend = "Trend"
    case buy = "Buy"
    case sell = "Sell"
    case alert = "Alert"
    case custom = "Custom"
    
    /// The SF Symbol name for the annotation type
    var iconName: String {
        switch self {
        case .note:
            return "text.bubble"
        case .support:
            return "arrow.up.circle"
        case .resistance:
            return "arrow.down.circle"
        case .trend:
            return "arrow.up.right.circle"
        case .buy:
            return "arrow.up.circle.fill"
        case .sell:
            return "arrow.down.circle.fill"
        case .alert:
            return "exclamationmark.circle.fill"
        case .custom:
            return "info.circle.fill"
        }
    }
    
    /// The color associated with the annotation type
    var color: Color {
        switch self {
        case .note:
            return .blue
        case .support:
            return .green
        case .resistance:
            return .red
        case .trend:
            return .orange
        case .buy:
            return .green
        case .sell:
            return .red
        case .alert:
            return .yellow
        case .custom:
            return .blue
        }
    }
}

/// Represents volume data for volume charts
struct VolumeData: Identifiable, Hashable {
    // MARK: - Properties
    
    let id = UUID()
    let date: Date
    let volume: Double
    let isUp: Bool
    
    /// Converts to chart data entry format
    var chartDataEntry: (x: TimeInterval, y: Double) {
        (date.timeIntervalSince1970, volume)
    }
    
    /// The color to use for the volume bar
    var color: Color {
        isUp ? .green.opacity(0.8) : .red.opacity(0.8)
    }
    
    // MARK: - Hashable
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: VolumeData, rhs: VolumeData) -> Bool {
        lhs.id == rhs.id &&
        lhs.date == rhs.date &&
        abs(lhs.volume - rhs.volume) < .ulpOfOne &&
        lhs.isUp == rhs.isUp
    }
}

/// Chart data model containing all data needed for rendering
struct ChartData: Hashable {
    // MARK: - Properties
    
    let candles: [StockBarData]
    let volume: [VolumeData]
    let dates: [Date]
    let indicators: [String: [Double]]
    let annotations: [ChartAnnotation]
    
    // MARK: - Initialization
    
    init(candles: [StockBarData],
         indicators: [String: [Double]] = [:],
         annotations: [ChartAnnotation] = []) {
        self.candles = candles
        self.volume = candles.map(VolumeData.fromBarData)
        self.dates = candles.map(\.timestamp)
        self.indicators = indicators
        self.annotations = annotations
    }
    
    // MARK: - Computed Properties
    
    /// The date range of the chart data
    var dateRange: ClosedRange<Date> {
        guard let first = dates.first, let last = dates.last else {
            return Date()...Date()
        }
        return first...last
    }
    
    /// The price range of the chart data
    var priceRange: ClosedRange<Double> {
        let prices = candles.flatMap { [$0.highPrice, $0.lowPrice] }
        guard let min = prices.min(), let max = prices.max() else {
            return 0...100
        }
        let padding = (max - min) * 0.1
        return (min - padding)...(max + padding)
    }
    
    /// The volume range of the chart data
    var volumeRange: ClosedRange<Double> {
        guard let min = volume.map(\.volume).min(),
              let max = volume.map(\.volume).max() else {
            return 0...100
        }
        let padding = (max - min) * 0.1
        return (min - padding)...(max + padding)
    }
    
    // MARK: - Hashable
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(candles)
        hasher.combine(volume)
        hasher.combine(dates)
        hasher.combine(annotations)
    }
    
    static func == (lhs: ChartData, rhs: ChartData) -> Bool {
        lhs.candles == rhs.candles &&
        lhs.volume == rhs.volume &&
        lhs.dates == rhs.dates &&
        lhs.annotations == rhs.annotations
    }
}

// MARK: - Factory Methods

extension VolumeData {
    /// Creates a VolumeData instance from a StockBarData instance
    /// - Parameter bar: The StockBarData to convert
    /// - Returns: A new VolumeData instance
    static func fromBarData(_ bar: StockBarData) -> VolumeData {
        VolumeData(
            date: bar.timestamp,
            volume: bar.volume,
            isUp: bar.isUpward
        )
    }
}

// MARK: - Mock Data

extension ChartData {
    /// Creates mock chart data for testing and preview purposes
    /// - Parameters:
    ///   - symbol: The stock symbol
    ///   - days: Number of days of data
    /// - Returns: A ChartData instance with mock data
    static func mock(symbol: String = "AAPL", days: Int = 30) -> ChartData {
        let candles = StockBarData.mockData(symbol: symbol, days: days)
        let annotations = [
            ChartAnnotation(
                type: .buy,
                date: candles[5].timestamp,
                price: candles[5].lowPrice,
                text: "Strong support"
            ),
            ChartAnnotation(
                type: .sell,
                date: candles[15].timestamp,
                price: candles[15].highPrice,
                text: "Resistance level"
            )
        ]
        return ChartData(candles: candles, annotations: annotations)
    }
}
