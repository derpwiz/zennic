import SwiftUI
import Charts

struct PortfolioChartView: View {
    let pricePoints: [PricePoint]
    
    var body: some View {
        Group {
            if pricePoints.isEmpty {
                Text("No portfolio data available")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Chart(pricePoints) { point in
                    LineMark(
                        x: .value("Time", point.date),
                        y: .value("Value", point.price)
                    )
                    .foregroundStyle(Color.blue.gradient)
                    
                    AreaMark(
                        x: .value("Time", point.date),
                        y: .value("Value", point.price)
                    )
                    .foregroundStyle(Color.blue.opacity(0.1))
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .hour)) { _ in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel(format: .dateTime.hour())
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel {
                            if let doubleValue = value.as(Double.self) {
                                Text(String(format: "$%.2f", doubleValue))
                            }
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    let mockData = [
        PricePoint(date: Date().addingTimeInterval(-3600 * 4), price: 1000.0),
        PricePoint(date: Date().addingTimeInterval(-3600 * 3), price: 1050.0),
        PricePoint(date: Date().addingTimeInterval(-3600 * 2), price: 1025.0),
        PricePoint(date: Date().addingTimeInterval(-3600), price: 1075.0),
        PricePoint(date: Date(), price: 1100.0)
    ]
    
    return PortfolioChartView(pricePoints: mockData)
        .frame(height: 300)
}
