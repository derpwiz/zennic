import Foundation
import SwiftUI

/// Represents a price point at a specific date
struct PricePoint: Codable, Identifiable, Hashable {
    var id: UUID
    let date: Date
    let price: Double
    
    init(date: Date, price: Double) {
        self.id = UUID()
        self.date = date
        self.price = price
    }
    
    /// Converts to chart data entry format
    var chartDataEntry: (x: TimeInterval, y: Double) {
        (date.timeIntervalSince1970, price)
    }
    
    // MARK: - Hashable
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: PricePoint, rhs: PricePoint) -> Bool {
        lhs.id == rhs.id &&
        lhs.date == rhs.date &&
        abs(lhs.price - rhs.price) < .ulpOfOne
    }
}
