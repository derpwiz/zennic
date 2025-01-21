import Foundation
import DGCharts

/// Represents a single candlestick data point
struct CandleStickData {
    let date: Date
    let open: Double
    let high: Double
    let low: Double
    let close: Double
    let volume: Double
    
    var candleData: CandleChartDataEntry {
        CandleChartDataEntry(
            x: date.timeIntervalSince1970,
            shadowH: high,
            shadowL: low,
            open: open,
            close: close
        )
    }
}

/// Represents a price point for line charts
struct PricePoint {
    let date: Date
    let price: Double
    
    var chartDataEntry: ChartDataEntry {
        ChartDataEntry(x: date.timeIntervalSince1970, y: price)
    }
}

/// Represents volume data for volume charts
struct VolumeData {
    let date: Date
    let volume: Double
    let isUpDay: Bool
    
    var chartDataEntry: BarChartDataEntry {
        BarChartDataEntry(x: date.timeIntervalSince1970, y: volume)
    }
}

/// Chart time period options
enum ChartTimePeriod: String, CaseIterable {
    case day = "1D"
    case week = "1W"
    case month = "1M"
    case threeMonths = "3M"
    case year = "1Y"
    case fiveYears = "5Y"
    
    var interval: TimeInterval {
        switch self {
        case .day: return 24 * 60 * 60
        case .week: return 7 * 24 * 60 * 60
        case .month: return 30 * 24 * 60 * 60
        case .threeMonths: return 90 * 24 * 60 * 60
        case .year: return 365 * 24 * 60 * 60
        case .fiveYears: return 5 * 365 * 24 * 60 * 60
        }
    }
}
