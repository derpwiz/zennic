import SwiftUI
import DGCharts

struct PortfolioChartView: NSViewRepresentable {
    let pricePoints: [PricePoint]
    var showGrid: Bool = true
    var fillColor: NSColor = .systemBlue.withAlphaComponent(0.3)
    var lineColor: NSColor = .systemBlue
    
    func makeNSView(context: Context) -> LineChartView {
        let chart = LineChartView()
        setupChart(chart)
        return chart
    }
    
    func updateNSView(_ chart: LineChartView, context: Context) {
        updateChartData(chart)
    }
    
    private func setupChart(_ chart: LineChartView) {
        // General setup
        chart.dragEnabled = true
        chart.setScaleEnabled(true)
        chart.pinchZoomEnabled = true
        chart.doubleTapToZoomEnabled = true
        
        // X-axis setup
        let xAxis = chart.xAxis
        xAxis.labelPosition = .bottom
        xAxis.labelFont = .systemFont(ofSize: 10)
        xAxis.valueFormatter = DateAxisValueFormatter()
        xAxis.drawGridLinesEnabled = showGrid
        
        // Left Y-axis setup
        let leftAxis = chart.leftAxis
        leftAxis.labelFont = .systemFont(ofSize: 10)
        leftAxis.labelCount = 6
        leftAxis.valueFormatter = CurrencyAxisValueFormatter()
        leftAxis.drawGridLinesEnabled = showGrid
        
        // Right Y-axis setup
        chart.rightAxis.enabled = false
        
        // Legend setup
        chart.legend.enabled = false
        
        // Description
        chart.chartDescription.enabled = false
    }
    
    private func updateChartData(_ chart: LineChartView) {
        let entries = pricePoints.map { $0.chartDataEntry }
        let dataSet = LineChartDataSet(entries: entries)
        
        // Customize the line
        dataSet.mode = .cubicBezier
        dataSet.drawCirclesEnabled = false
        dataSet.lineWidth = 2
        dataSet.setColor(lineColor)
        
        // Fill setup
        dataSet.fillAlpha = 1
        dataSet.fill = ColorFill(color: fillColor)
        dataSet.drawFilledEnabled = true
        
        // Customize value points
        dataSet.drawValuesEnabled = false
        
        // Create and set chart data
        let data = LineChartData(dataSet: dataSet)
        chart.data = data
        
        // Refresh
        chart.notifyDataSetChanged()
    }
}

class CurrencyAxisValueFormatter: NSObject, AxisValueFormatter {
    private let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter
    }()
    
    func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        if value >= 1_000_000 {
            return "$\(Int(value / 1_000_000))M"
        } else if value >= 1_000 {
            return "$\(Int(value / 1_000))K"
        }
        return numberFormatter.string(from: NSNumber(value: value)) ?? ""
    }
}

struct PortfolioPerformanceView: View {
    @ObservedObject var viewModel: RealTimeMarketViewModel
    @State private var selectedPeriod: ChartTimePeriod = .day
    
    var body: some View {
        VStack(spacing: 16) {
            // Period selector
            Picker("Time Period", selection: $selectedPeriod) {
                ForEach(ChartTimePeriod.allCases, id: \.self) { period in
                    Text(period.rawValue).tag(period)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            
            // Portfolio value
            Text(String(format: "$%.2f", viewModel.portfolioValue))
                .font(.system(.title, design: .rounded))
                .bold()
            
            // Chart
            PortfolioChartView(
                pricePoints: generateDummyData(for: selectedPeriod),
                showGrid: true,
                fillColor: .systemBlue.withAlphaComponent(0.1),
                lineColor: .systemBlue
            )
            .frame(height: 300)
            .padding()
        }
    }
    
    // Temporary dummy data generator - replace with real data
    private func generateDummyData(for period: ChartTimePeriod) -> [PricePoint] {
        let numberOfPoints = 100
        let interval = period.interval / Double(numberOfPoints)
        let startValue = 10000.0
        
        return (0..<numberOfPoints).map { i in
            let date = Date().addingTimeInterval(-period.interval + (Double(i) * interval))
            let randomChange = Double.random(in: -50...50)
            return PricePoint(
                date: date,
                price: startValue + randomChange
            )
        }
    }
}
