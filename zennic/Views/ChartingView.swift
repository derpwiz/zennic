import SwiftUI
import Charts
import AppKit

struct ChartingView: View {
    @StateObject private var viewModel: ChartingViewModel
    @State private var showingIndicatorSheet = false
    @Binding var selectedTimeframe: String
    @State private var chartScale: CGFloat = 1.0
    @State private var dragOffset: CGFloat = 0
    @SceneStorage("lastSymbol") private var lastSymbol: String = "AAPL"
    
    private let timeframes = ["1Min", "5Min", "15Min", "1Hour", "1Day", "1Week"]
    private let minScale: CGFloat = 1.0
    private let maxScale: CGFloat = 5.0
    
    init(selectedTimeframe: Binding<String> = .constant("1Day")) {
        let viewModel = ChartingViewModel()
        _viewModel = StateObject(wrappedValue: viewModel)
        _selectedTimeframe = selectedTimeframe
    }
    
    init(viewModel: ChartingViewModel, selectedTimeframe: Binding<String>) {
        _viewModel = StateObject(wrappedValue: viewModel)
        _selectedTimeframe = selectedTimeframe
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Symbol and Timeframe Selection
                HStack {
                    TextField("Symbol", text: $viewModel.selectedSymbol)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 100)
                        .accessibilityLabel("Stock Symbol")
                        .onAppear {
                            if viewModel.selectedSymbol.isEmpty {
                                viewModel.selectedSymbol = lastSymbol
                            }
                        }
                        .onChange(of: viewModel.selectedSymbol) { _, newValue in
                            lastSymbol = newValue
                        }
                    
                    Picker("Timeframe", selection: $selectedTimeframe) {
                        ForEach(timeframes, id: \.self) { timeframe in
                            Text(timeframe)
                                .tag(timeframe)
                                .accessibilityLabel("\(timeframe) timeframe")
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .accessibilityLabel("Chart Timeframe Selection")
                    
                    Button(action: { showingIndicatorSheet = true }) {
                        Image(systemName: "chart.xyaxis.line")
                            .foregroundColor(.accentColor)
                            .accessibilityLabel("Add Technical Indicators")
                    }
                }
                .padding()
                
                // Main Chart View
                ZStack {
                    if viewModel.isLoading {
                        LoadingView()
                    } else if let error = viewModel.error {
                        ErrorView(error: error) {
                            Task {
                                await viewModel.fetchChartData(symbol: viewModel.selectedSymbol, timeframe: selectedTimeframe)
                            }
                        }
                    } else {
                        ChartContainer(
                            data: viewModel.chartData,
                            indicators: viewModel.calculatedIndicators,
                            scale: $chartScale,
                            dragOffset: $dragOffset
                        )
                    }
                    
                    // Indicator Calculation Overlay
                    if viewModel.isCalculatingIndicators {
                        ProgressView("Calculating indicators...")
                            .padding()
                            .background(Color(nsColor: .windowBackgroundColor).opacity(0.8))
                            .cornerRadius(10)
                    }
                }
                
                // Indicator Values
                if !viewModel.calculatedIndicators.isEmpty {
                    IndicatorValuesView(
                        selectedIndicators: viewModel.selectedIndicators,
                        calculatedIndicators: viewModel.calculatedIndicators
                    )
                }
            }
            .navigationTitle("Chart")
            .sheet(isPresented: $showingIndicatorSheet) {
                IndicatorSelectionView(selectedIndicators: $viewModel.selectedIndicators)
            }
        }
    }
}

// MARK: - Supporting Views

struct LoadingView: View {
    var body: some View {
        VStack {
            ProgressView("Loading chart data...")
            Text("Please wait while we fetch the data")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top)
        }
        .accessibilityElement(children: .combine)
    }
}

struct ErrorView: View {
    let error: Error
    let retryAction: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.red)
            
            Text(error.localizedDescription)
                .multilineTextAlignment(.center)
                .padding()
            
            Button("Retry", action: retryAction)
                .buttonStyle(.bordered)
        }
        .accessibilityElement(children: .combine)
    }
}

struct ChartContainer: View {
    let data: [StockBarData]
    let indicators: [IndicatorType: [Double]]
    @Binding var scale: CGFloat
    @Binding var dragOffset: CGFloat
    
    @State private var selectedDataPoint: StockBarData?
    @State private var lastScale: CGFloat = 1.0
    @GestureState private var magnifyState: CGFloat = 1.0
    @GestureState private var dragState: CGSize = .zero
    
    private let minScale: CGFloat = 1.0
    private let maxScale: CGFloat = 5.0
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                ChartContent(
                    data: data,
                    indicators: indicators,
                    selectedDataPoint: $selectedDataPoint
                )
                .frame(
                    width: max((NSScreen.main?.frame.width ?? 800) * scale, NSScreen.main?.frame.width ?? 800),
                    height: (NSScreen.main?.frame.height ?? 600) * 0.6
                )
                .gesture(createCombinedGesture(proxy: proxy))
                .offset(x: dragState.width + dragOffset)
                .scaleEffect(magnifyState * lastScale)
            }
            .onChange(of: data) { _, _ in
                withAnimation(.easeInOut) {
                    proxy.scrollTo(data.count - 1, anchor: .trailing)
                }
            }
        }
        .overlay(
            selectedDataPoint.map { point in
                DataPointOverlay(point: point)
                    .padding()
                    .background(Color(nsColor: .windowBackgroundColor).opacity(0.9))
                    .cornerRadius(10)
                    .padding()
                    .transition(.opacity)
            }
        )
    }
    
    private func createCombinedGesture(proxy: ScrollViewProxy) -> some Gesture {
        SimultaneousGesture(
            createMagnificationGesture(),
            createDragGesture(proxy: proxy)
        )
    }
    
    private func createMagnificationGesture() -> some Gesture {
        MagnificationGesture()
            .updating($magnifyState) { value, state, _ in
                state = value
            }
            .onEnded { value in
                let newScale = lastScale * value
                scale = min(maxScale, max(minScale, newScale))
                lastScale = scale
            }
    }
    
    private func createDragGesture(proxy: ScrollViewProxy) -> some Gesture {
        DragGesture()
            .updating($dragState) { value, state, _ in
                state = value.translation
            }
            .onEnded { value in
                let velocity = value.predictedEndTranslation.width - value.translation.width
                withAnimation(.interpolatingSpring(stiffness: 170, damping: 15)) {
                    dragOffset = 0
                    if abs(velocity) > 100 {
                        let direction = velocity > 0 ? 1 : -1
                        proxy.scrollTo(data.count - 1 + direction, anchor: .trailing)
                    }
                }
            }
    }
}

struct ChartContent: View {
    let data: [StockBarData]
    let indicators: [IndicatorType: [Double]]
    @Binding var selectedDataPoint: StockBarData?
    
    var body: some View {
        Chart {
            // Candlesticks
            ForEach(data.indices, id: \.self) { index in
                let bar = data[index]
                
                RectangleMark(
                    x: .value("Time", bar.timestamp),
                    yStart: .value("Price", bar.lowPrice),
                    yEnd: .value("Price", bar.highPrice),
                    width: 2
                )
                .foregroundStyle(bar.closePrice > bar.openPrice ? .green : .red)
                .accessibilityLabel("High-Low range: \(formatPrice(bar.highPrice)) to \(formatPrice(bar.lowPrice))")
                
                RectangleMark(
                    x: .value("Time", bar.timestamp),
                    yStart: .value("Price", bar.openPrice),
                    yEnd: .value("Price", bar.closePrice),
                    width: 6
                )
                .foregroundStyle(bar.closePrice > bar.openPrice ? .green : .red)
                .accessibilityLabel("Open-Close range: \(formatPrice(bar.openPrice)) to \(formatPrice(bar.closePrice))")
            }
            
            // Technical Indicators
            ForEach(Array(indicators.keys), id: \.self) { indicator in
                let values = indicators[indicator] ?? []
                let dates = data.prefix(values.count).map(\.timestamp)
                
                ForEach(Array(zip(dates.indices, dates)), id: \.0) { index, date in
                    LineMark(
                        x: .value("Time", date),
                        y: .value("Value", values[index])
                    )
                    .foregroundStyle(indicatorColor(for: indicator))
                }
                .lineStyle(StrokeStyle(lineWidth: 1))
                .interpolationMethod(.monotone)
            }
        }
        .chartXScale(domain: chartXDomain)
        .chartYScale(domain: chartYDomain)
        .chartXAxis {
            AxisMarks(preset: .aligned, values: .automatic(desiredCount: 6)) { value in
                if let date = value.as(Date.self) {
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel {
                        let timeInterval = chartXDomain.upperBound.timeIntervalSince(chartXDomain.lowerBound)
                        if timeInterval > 86400 * 7 { // More than a week
                            Text(date, format: .dateTime.month().day())
                        } else if timeInterval > 86400 { // More than a day
                            Text(date, format: .dateTime.weekday().hour())
                        } else { // Less than a day
                            Text(date, format: .dateTime.hour().minute())
                        }
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(preset: .aligned, position: .leading, values: .automatic(desiredCount: 8)) { value in
                if let price = value.as(Double.self) {
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel {
                        Text(formatPrice(price))
                            .monospacedDigit()
                    }
                }
            }
        }
        .chartOverlay { proxy in
            GeometryReader { geometry in
                Rectangle().fill(.clear).contentShape(Rectangle())
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                let x = value.location.x
                                guard let index = findDataPoint(at: x, proxy: proxy, geometry: geometry) else { return }
                                selectedDataPoint = data[index]
                            }
                            .onEnded { _ in
                                selectedDataPoint = nil
                            }
                    )
            }
        }
    }
    
    private var chartXDomain: ClosedRange<Date> {
        guard let first = data.first?.timestamp,
              let last = data.last?.timestamp else {
            return Date()...Date()
        }
        return first...last
    }
    
    private var chartYDomain: ClosedRange<Double> {
        let prices = data.flatMap { [$0.highPrice, $0.lowPrice] }
        let indicatorValues = indicators.values.flatMap { $0 }.filter { $0 != 0 }
        let allValues = prices + indicatorValues
        
        guard let min = allValues.min(),
              let max = allValues.max() else {
            return 0...100
        }
        
        let padding = (max - min) * 0.1
        return (min - padding)...(max + padding)
    }
    
    private func formatPrice(_ price: Double) -> String {
        String(format: "%.2f", price)
    }
    
    private func indicatorColor(for type: IndicatorType) -> Color {
        switch type {
        case .sma(_): return .blue.opacity(0.8)
        case .ema(_): return .orange.opacity(0.8)
        case .rsi(_): return .purple.opacity(0.8)
        case .macd(_, _, _): return .yellow.opacity(0.8)
        }
    }
    
    private func findDataPoint(at x: CGFloat, proxy: ChartProxy, geometry: GeometryProxy) -> Int? {
        let relativeX = x / geometry.size.width
        guard let date = proxy.value(atX: relativeX) as Date? else { return nil }
        
        // Find the closest data point using binary search
        var left = 0
        var right = data.count - 1
        
        while left <= right {
            let mid = (left + right) / 2
            let midDate = data[mid].timestamp
            
            let timeDiff = abs(midDate.timeIntervalSince(date))
            if timeDiff < 60 * 30 { // Within 30 minutes
                return mid
            }
            
            if midDate < date {
                left = mid + 1
            } else {
                right = mid - 1
            }
        }
        
        // If no exact match found, return the closest point
        if left >= data.count {
            return data.count - 1
        }
        if right < 0 {
            return 0
        }
        
        let leftDiff = abs(data[left].timestamp.timeIntervalSince(date))
        let rightDiff = abs(data[right].timestamp.timeIntervalSince(date))
        return leftDiff < rightDiff ? left : right
    }
}

struct DataPointOverlay: View {
    let point: StockBarData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(formatDate(point.timestamp))
                .font(.caption)
                .foregroundColor(.secondary)
            
            Group {
                DataRow(label: "Open", value: point.openPrice)
                DataRow(label: "High", value: point.highPrice)
                DataRow(label: "Low", value: point.lowPrice)
                DataRow(label: "Close", value: point.closePrice)
                DataRow(label: "Volume", value: Double(point.volume))
            }
        }
        .accessibilityElement(children: .combine)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct DataRow: View {
    let label: String
    let value: Double
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(String(format: "%.2f", value))
                .monospacedDigit()
        }
        .font(.caption)
    }
}

struct IndicatorValuesView: View {
    let selectedIndicators: Set<IndicatorType>
    let calculatedIndicators: [IndicatorType: [Double]]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(Array(selectedIndicators), id: \.self) { indicator in
                    IndicatorValueView(
                        type: indicator,
                        values: calculatedIndicators[indicator] ?? []
                    )
                }
            }
            .padding()
        }
        .frame(height: 60)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

struct IndicatorValueView: View {
    let type: IndicatorType
    let values: [Double]
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(type.description)
                .font(.caption)
                .foregroundColor(.secondary)
            
            if let lastValue = values.last {
                Text(String(format: "%.2f", lastValue))
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.primary)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(type.description): \(values.last.map { String(format: "%.2f", $0) } ?? "N/A")")
    }
}

struct IndicatorSelectionView: View {
    @Binding var selectedIndicators: Set<IndicatorType>
    @Environment(\.dismiss) var dismiss
    
    private static let availableIndicators: [IndicatorType] = [
        .sma(period: 14),
        .ema(period: 14),
        .rsi(period: 14),
        .macd(fastPeriod: 12, slowPeriod: 26, signalPeriod: 9)
    ]
    
    var body: some View {
        NavigationView {
            List {
                ForEach(Self.availableIndicators, id: \.self) { indicator in
                    IndicatorToggleRow(
                        indicator: indicator,
                        isSelected: selectedIndicators.contains(indicator),
                        onToggle: { isSelected in
                            if isSelected {
                                selectedIndicators.insert(indicator)
                            } else {
                                selectedIndicators.remove(indicator)
                            }
                        }
                    )
                }
            }
            .navigationTitle("Indicators")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct IndicatorToggleRow: View {
    let indicator: IndicatorType
    let isSelected: Bool
    let onToggle: (Bool) -> Void
    
    var body: some View {
        Section {
            Toggle(isOn: Binding(
                get: { isSelected },
                set: onToggle
            )) {
                VStack(alignment: .leading) {
                    Text(indicator.description)
                        .font(.headline)
                    Text(indicator.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .accessibilityLabel("\(indicator.description) indicator")
            .accessibilityHint(indicator.description)
        }
    }
}

#Preview {
    ChartingView()
}
