import SwiftUI
import DGCharts

struct AdvancedChartView: NSViewRepresentable {
    let candleStickData: [CandleStickData]
    let volumeData: [VolumeData]
    var indicators: [IndicatorData] = []
    var annotations: [ChartAnnotation] = []
    
    // Chart customization
    var showVolume: Bool = true
    var showLegend: Bool = true
    var enableZoom: Bool = true
    var showGrid: Bool = true
    
    // Appearance
    var upColor: NSColor = .systemGreen
    var downColor: NSColor = .systemRed
    var volumeUpColor: NSColor = .systemGreen.withAlphaComponent(0.5)
    var volumeDownColor: NSColor = .systemRed.withAlphaComponent(0.5)
    
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
        chart.setScaleEnabled(enableZoom)
        chart.pinchZoomEnabled = true
        chart.doubleTapToZoomEnabled = true
        chart.autoScaleMinMaxEnabled = true
        
        // X-axis setup
        let xAxis = chart.xAxis
        xAxis.labelPosition = .bottom
        xAxis.labelFont = .systemFont(ofSize: 10)
        xAxis.valueFormatter = DateAxisValueFormatter()
        xAxis.drawGridLinesEnabled = showGrid
        
        // Left Y-axis setup
        let leftAxis = chart.leftAxis
        leftAxis.labelFont = .systemFont(ofSize: 10)
        leftAxis.labelCount = 8
        leftAxis.valueFormatter = CurrencyAxisValueFormatter()
        leftAxis.drawGridLinesEnabled = showGrid
        leftAxis.spaceTop = 0.1
        leftAxis.spaceBottom = 0.1
        
        // Right Y-axis setup (for volume)
        let rightAxis = chart.rightAxis
        if showVolume {
            rightAxis.enabled = true
            rightAxis.labelFont = .systemFont(ofSize: 10)
            rightAxis.labelCount = 4
            rightAxis.valueFormatter = VolumeAxisValueFormatter()
            rightAxis.axisMinimum = 0
        } else {
            rightAxis.enabled = false
        }
        
        // Legend setup
        chart.legend.enabled = showLegend
        chart.legend.font = .systemFont(ofSize: 10)
        chart.legend.form = .circle
        chart.legend.formSize = 8
        chart.legend.textColor = .labelColor
        
        // Description
        chart.chartDescription.enabled = false
        
        // Marker
        let marker = ChartMarker()
        marker.chartView = chart
        chart.marker = marker
    }
    
    private func updateChartData(_ chart: CombinedChartView) {
        var dataSets: [ChartDataSetProtocol] = []
        
        // Candlestick data
        let candleEntries = candleStickData.enumerated().map { (index, data) -> CandleChartDataEntry in
            CandleChartDataEntry(
                x: Double(index),
                shadowH: data.high,
                shadowL: data.low,
                open: data.open,
                close: data.close
            )
        }
        
        let candleDataSet = CandleChartDataSet(entries: candleEntries, label: "Price")
        setupCandleDataSet(candleDataSet)
        dataSets.append(candleDataSet)
        
        // Volume data
        if showVolume {
            let volumeEntries = volumeData.enumerated().map { (index, data) -> BarChartDataEntry in
                BarChartDataEntry(x: Double(index), y: data.volume)
            }
            
            let volumeDataSet = BarChartDataSet(entries: volumeEntries, label: "Volume")
            setupVolumeDataSet(volumeDataSet)
            dataSets.append(volumeDataSet)
        }
        
        // Technical indicators
        for indicator in indicators {
            let indicatorDataSets = createIndicatorDataSets(indicator)
            dataSets.append(contentsOf: indicatorDataSets)
        }
        
        // Create combined data
        let combinedData = CombinedChartData()
        combinedData.candleData = CandleChartData(dataSet: candleDataSet)
        
        if showVolume {
            combinedData.barData = BarChartData(dataSets: [volumeDataSet])
        }
        
        if !indicators.isEmpty {
            combinedData.lineData = LineChartData(dataSets: dataSets.filter { $0 is LineChartDataSet })
        }
        
        chart.data = combinedData
        
        // Add annotations
        addAnnotations(to: chart)
        
        // Refresh
        chart.notifyDataSetChanged()
    }
    
    private func setupCandleDataSet(_ dataSet: CandleChartDataSet) {
        dataSet.shadowColorSameAsCandle = true
        dataSet.increasingColor = upColor
        dataSet.increasingFilled = true
        dataSet.decreasingColor = downColor
        dataSet.decreasingFilled = true
        dataSet.neutralColor = .gray
        dataSet.drawValuesEnabled = false
        dataSet.shadowWidth = 0.7
    }
    
    private func setupVolumeDataSet(_ dataSet: BarChartDataSet) {
        dataSet.colors = volumeData.map { $0.isUpDay ? volumeUpColor : volumeDownColor }
        dataSet.drawValuesEnabled = false
        dataSet.axisDependency = .right
    }
    
    private func createIndicatorDataSets(_ indicator: IndicatorData) -> [ChartDataSetProtocol] {
        var dataSets: [ChartDataSetProtocol] = []
        
        // Main indicator line
        let entries = indicator.points.enumerated().map { (index, point) in
            ChartDataEntry(x: Double(index), y: point.value)
        }
        
        let mainDataSet = LineChartDataSet(entries: entries, label: "\(indicator.type.rawValue) (\(indicator.period))")
        setupIndicatorDataSet(mainDataSet, for: indicator.type)
        dataSets.append(mainDataSet)
        
        // Additional lines (e.g., signal line for MACD)
        for (name, points) in indicator.additionalData {
            let additionalEntries = points.enumerated().map { (index, point) in
                ChartDataEntry(x: Double(index), y: point.value)
            }
            let additionalDataSet = LineChartDataSet(entries: additionalEntries, label: name)
            setupIndicatorDataSet(additionalDataSet, for: indicator.type, isSecondary: true)
            dataSets.append(additionalDataSet)
        }
        
        return dataSets
    }
    
    private func setupIndicatorDataSet(_ dataSet: LineChartDataSet, for type: IndicatorType, isSecondary: Bool = false) {
        dataSet.drawCirclesEnabled = false
        dataSet.lineWidth = 1
        dataSet.drawValuesEnabled = false
        
        switch type {
        case .sma:
            dataSet.setColor(.systemBlue.withAlphaComponent(0.8))
        case .ema:
            dataSet.setColor(.systemPurple.withAlphaComponent(0.8))
        case .rsi:
            dataSet.setColor(.systemOrange.withAlphaComponent(0.8))
        case .macd:
            if isSecondary {
                dataSet.setColor(.systemRed.withAlphaComponent(0.8))
            } else {
                dataSet.setColor(.systemBlue.withAlphaComponent(0.8))
            }
        case .bollingerBands:
            if isSecondary {
                dataSet.setColor(.systemGray.withAlphaComponent(0.5))
                dataSet.drawFilledEnabled = true
                dataSet.fillAlpha = 0.1
            } else {
                dataSet.setColor(.systemGray.withAlphaComponent(0.8))
            }
        }
    }
    
    private func addAnnotations(to chart: CombinedChartView) {
        // Remove existing annotations
        chart.removeAllViews()
        
        for annotation in annotations {
            let view = createAnnotationView(annotation)
            chart.addSubview(view)
            
            // Position the annotation
            if let entry = chart.data?.entryForHighlight(Highlight(
                x: annotation.date.timeIntervalSince1970,
                y: annotation.price,
                dataSetIndex: 0
            )) {
                let point = chart.getTransformer(forAxis: .left).pixelForValues(x: entry.x, y: entry.y)
                view.frame.origin = CGPoint(x: point.x - view.frame.width/2, y: point.y - view.frame.height)
            }
        }
    }
    
    private func createAnnotationView(_ annotation: ChartAnnotation) -> NSView {
        let container = NSView(frame: NSRect(x: 0, y: 0, width: 60, height: 40))
        
        let imageView = NSImageView(frame: NSRect(x: 20, y: 20, width: 20, height: 20))
        imageView.image = annotation.type.image
        container.addSubview(imageView)
        
        let label = NSTextField(frame: NSRect(x: 0, y: 0, width: 60, height: 20))
        label.stringValue = annotation.text
        label.alignment = .center
        label.isBezeled = false
        label.drawsBackground = false
        label.isEditable = false
        container.addSubview(label)
        
        return container
    }
}

// MARK: - Supporting Types

class ChartMarker: MarkerView {
    private let label = NSTextField()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLabel()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLabel()
    }
    
    private func setupLabel() {
        label.isBezeled = false
        label.drawsBackground = true
        label.backgroundColor = .windowBackgroundColor
        label.textColor = .labelColor
        label.font = .systemFont(ofSize: 10)
        label.alignment = .center
        addSubview(label)
    }
    
    override func refreshContent(entry: ChartDataEntry, highlight: Highlight) {
        let date = Date(timeIntervalSince1970: entry.x)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd HH:mm"
        
        let price = String(format: "%.2f", entry.y)
        label.stringValue = "\(dateFormatter.string(from: date))\n$\(price)"
        label.sizeToFit()
        
        var rect = label.frame
        rect.size.width += 20
        rect.size.height += 10
        self.frame = rect
        
        label.frame = bounds.insetBy(dx: 10, dy: 5)
    }
}

// MARK: - Chart Annotations

struct ChartAnnotation {
    enum AnnotationType {
        case buy
        case sell
        case alert
        case note
        
        var image: NSImage? {
            switch self {
            case .buy: return NSImage(systemSymbolName: "arrow.up.circle.fill", accessibilityDescription: nil)
            case .sell: return NSImage(systemSymbolName: "arrow.down.circle.fill", accessibilityDescription: nil)
            case .alert: return NSImage(systemSymbolName: "exclamationmark.circle.fill", accessibilityDescription: nil)
            case .note: return NSImage(systemSymbolName: "text.bubble.fill", accessibilityDescription: nil)
            }
        }
    }
    
    let type: AnnotationType
    let date: Date
    let price: Double
    let text: String
}
