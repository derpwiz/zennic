import SwiftUI
import Charts

struct StockChartView: View {
    let candleStickData: [StockBarData]
    let volumeData: [VolumeData]
    
    var body: some View {
        VStack {
            // Price chart
            Chart(candleStickData) { candle in
                RectangleMark(
                    x: .value("Time", candle.timestamp),
                    yStart: .value("Low", candle.lowPrice),
                    yEnd: .value("High", candle.highPrice),
                    width: 2
                )
                .foregroundStyle(.gray)
                
                RectangleMark(
                    x: .value("Time", candle.timestamp),
                    yStart: .value("Open/Close", min(candle.openPrice, candle.closePrice)),
                    yEnd: .value("Open/Close", max(candle.openPrice, candle.closePrice)),
                    width: 8
                )
                .foregroundStyle(candle.closePrice >= candle.openPrice ? .green : .red)
            }
            .frame(height: 200)
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
            
            // Volume chart
            Chart(volumeData) { volume in
                BarMark(
                    x: .value("Time", volume.date),
                    y: .value("Volume", volume.volume)
                )
                .foregroundStyle(volume.isUp ? .green.opacity(0.5) : .red.opacity(0.5))
            }
            .frame(height: 80)
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
                            Text(String(format: "%.0f", doubleValue))
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    let now = Date()
    let candleData = [
        StockBarData(symbol: "AAPL", timestamp: now, openPrice: 150.0, highPrice: 155.0, lowPrice: 148.0, closePrice: 152.0, volume: 1000000),
        StockBarData(symbol: "AAPL", timestamp: now.addingTimeInterval(3600), openPrice: 152.0, highPrice: 158.0, lowPrice: 151.0, closePrice: 157.0, volume: 1200000),
        StockBarData(symbol: "AAPL", timestamp: now.addingTimeInterval(7200), openPrice: 157.0, highPrice: 160.0, lowPrice: 155.0, closePrice: 156.0, volume: 800000)
    ]
    
    let volumeData = candleData.map {
        VolumeData(date: $0.timestamp, volume: $0.volume, isUp: $0.closePrice >= $0.openPrice)
    }
    
    StockChartView(candleStickData: candleData, volumeData: volumeData)
        .frame(height: 300)
}
