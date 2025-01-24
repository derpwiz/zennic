import Foundation

/// Represents different time periods for chart data
enum ChartTimePeriod: String, CaseIterable, Equatable {
    case day = "1D"
    case week = "1W"
    case month = "1M"
    case threeMonths = "3M"
    case year = "1Y"
    case all = "ALL"
    
    var days: Int {
        switch self {
        case .day:
            return 1
        case .week:
            return 7
        case .month:
            return 30
        case .threeMonths:
            return 90
        case .year:
            return 365
        case .all:
            return 3650 // 10 years
        }
    }
    
    var timeframe: String {
        switch self {
        case .day:
            return "1Min"
        case .week:
            return "5Min"
        case .month:
            return "15Min"
        case .threeMonths:
            return "1H"
        case .year, .all:
            return "1D"
        }
    }
}
