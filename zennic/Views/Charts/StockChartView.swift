import SwiftUI
import DGCharts

struct StockChartView: NSViewRepresentable {
    let candleStickData: [CandleStickData]
    let volumeData: [VolumeData]
    var showVolume: Bool = true
    
    func makeNSView(context: Context) -> CombinedChartView {
        let chart = CombinedChartView()
        setupChart(chart)
        return chart
    }
    
    func updateNSView(_ chart: CombinedChartView, context: Context) {
        updateChartData(chart)
    }
    
    private func setupChart(_ chart: CombinedChartView) {
        // General setup
        chart.dragEnabled = true
        chart.setScaleEnabled(true)
        chart.pinchZoomEnabled = true
        chart.doubleTapToZoomEnabled = true
        chart.maxVisibleCount = 60
        
        // X-axis setup
        let xAxis = chart.xAxis
        xAxis.labelPosition = .bottom
        xAxis.labelFont = .systemFont(ofSize: 10)
        xAxis.valueFormatter = DateAxisValueFormatter()
        
        // Left Y-axis (price)
        let leftAxis = chart.leftAxis
        leftAxis.labelFont = .systemFont(ofSize: 10)
        leftAxis.labelCount = 7
        leftAxis.drawGridLinesEnabled = true
        leftAxis.valueFormatter = PriceAxisValueFormatter()
        
        // Right Y-axis (volume)
        let rightAxis = chart.rightAxis
        rightAxis.enabled = showVolume
        if showVolume {
            rightAxis.labelFont = .systemFont(ofSize: 10)
            rightAxis.labelCount = 7
            rightAxis.valueFormatter = VolumeAxisValueFormatter()
        }
        
        // Legend
        chart.legend.font = .systemFont(ofSize: 11)
        chart.legend.form = .line
        chart.legend.formSize = 8
        chart.legend.formLineWidth = 1.5
        chart.legend.textColor = .labelColor
        
        // Description
        chart.chartDescription.enabled = false
    }
    
    private func updateChartData(_ chart: CombinedChartView) {
        // Prepare candle data
        let candleDataSet = CandleChartDataSet(entries: candleStickData.map { $0.candleData })
        candleDataSet.label = "Price"
        candleDataSet.axisDependency = .left
        candleDataSet.shadowColor = .black
        candleDataSet.shadowWidth = 0.7
        candleDataSet.decreasingColor = .systemRed
        candleDataSet.decreasingFilled = true
        candleDataSet.increasingColor = .systemGreen
        candleDataSet.increasingFilled = true
        candleDataSet.neutralColor = .gray
        
        // Prepare volume data if needed
        var dataSets: [ChartDataSetProtocol] = [candleDataSet]
        if showVolume {
            let volumeDataSet = BarChartDataSet(entries: volumeData.map { $0.chartDataEntry })
            volumeDataSet.label = "Volume"
            volumeDataSet.axisDependency = .right
            volumeDataSet.colors = volumeData.map { $0.isUpDay ? NSColor.systemGreen.withAlphaComponent(0.5) : NSColor.systemRed.withAlphaComponent(0.5) }
            volumeDataSet.drawValuesEnabled = false
            dataSets.append(volumeDataSet)
        }
        
        // Update chart data
        let combinedData = CombinedChartData()
        combinedData.candleData = CandleChartData(dataSet: candleDataSet)
        if showVolume {
            combinedData.barData = BarChartData(dataSet: dataSets[1] as! BarChartDataSet)
        }
        chart.data = combinedData
        
        // Refresh
        chart.notifyDataSetChanged()
    }
}

class DateAxisValueFormatter: NSObject, AxisValueFormatter {
    func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        let date = Date(timeIntervalSince1970: value)
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd HH:mm"
        return formatter.string(from: date)
    }
}

class PriceAxisValueFormatter: NSObject, AxisValueFormatter {
    func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        String(format: "$%.2f", value)
    }
}

class VolumeAxisValueFormatter: NSObject, AxisValueFormatter {
    func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1
        
        if value >= 1_000_000 {
            return "\(formatter.string(from: NSNumber(value: value / 1_000_000)) ?? "")M"
        } else if value >= 1_000 {
            return "\(formatter.string(from: NSNumber(value: value / 1_000)) ?? "")K"
        }
        return formatter.string(from: NSNumber(value: value)) ?? ""
    }
}
