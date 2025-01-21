import SwiftUI

struct ChartingView: View {
    @EnvironmentObject private var appViewModel: AppViewModel
    @State private var selectedSymbol: String = "AAPL"
    @State private var timeframe: String = "1Min"
    @State private var selectedPeriod: ChartTimePeriod = .day
    @State private var selectedIndicators: Set<IndicatorType> = []
    @State private var showingIndicatorSheet = false
    @State private var indicatorPeriods: [IndicatorType: Int] = [:]
    @State private var annotations: [ChartAnnotation] = []
    @State private var showingAnnotationSheet = false
    @State private var newAnnotationType: ChartAnnotation.AnnotationType = .note
    @State private var newAnnotationText: String = ""
    
    private let availableTimeframes = ["1Min", "5Min", "15Min", "1H", "1D"]
    
    var body: some View {
        VStack(spacing: 16) {
            // Symbol search
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Enter Symbol", text: $selectedSymbol)
                    .textFieldStyle(.roundedBorder)
                    .accessibilityLabel("Stock Symbol")
            }
            .padding(.horizontal)
            
            // Time controls
            VStack(spacing: 12) {
                // Timeframe selector
                Picker("Chart Interval", selection: $timeframe) {
                    ForEach(availableTimeframes, id: \.self) { timeframe in
                        Text(timeframe)
                            .tag(timeframe)
                            .accessibilityLabel("\(timeframe) interval")
                    }
                }
                .pickerStyle(.segmented)
                
                // Period selector
                Picker("Time Range", selection: $selectedPeriod) {
                    ForEach(ChartTimePeriod.allCases, id: \.self) { period in
                        Text(period.rawValue)
                            .tag(period)
                            .accessibilityLabel("\(period.rawValue) range")
                    }
                }
                .pickerStyle(.segmented)
            }
            .padding(.horizontal)
            
            // Chart controls
            HStack(spacing: 16) {
                Spacer()
                
                Button {
                    showingIndicatorSheet = true
                } label: {
                    Label("Indicators", systemImage: "chart.xyaxis.line")
                        .labelStyle(.titleAndIcon)
                }
                .buttonStyle(.bordered)
                .accessibilityHint("Add or remove technical indicators")
                
                Button {
                    showingAnnotationSheet = true
                } label: {
                    Label("Add Note", systemImage: "plus.bubble")
                        .labelStyle(.titleAndIcon)
                }
                .buttonStyle(.bordered)
                .accessibilityHint("Add annotation to the chart")
            }
            .padding(.horizontal)
            
            // Main chart
            if let candleData = appViewModel.realTimeMarket.candleStickData[selectedSymbol] {
                AdvancedChartView(
                    candleStickData: candleData,
                    volumeData: candleData.map {
                        VolumeData(
                            date: $0.date,
                            volume: $0.volume,
                            isUpDay: $0.close >= $0.open
                        )
                    },
                    indicators: calculateIndicators(for: candleData),
                    annotations: annotations
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .sheet(isPresented: $showingIndicatorSheet) {
            NavigationView {
                IndicatorSelectionView(
                    selectedIndicators: $selectedIndicators,
                    indicatorPeriods: $indicatorPeriods
                )
                .navigationTitle("Technical Indicators")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            showingIndicatorSheet = false
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") {
                            showingIndicatorSheet = false
                        }
                    }
                }
            }
            .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showingAnnotationSheet) {
            NavigationView {
                AnnotationEditorView(
                    type: $newAnnotationType,
                    text: $newAnnotationText,
                    onSave: addAnnotation
                )
                .navigationTitle("Add Annotation")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            showingAnnotationSheet = false
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Add") {
                            addAnnotation()
                        }
                    }
                }
            }
            .presentationDetents([.medium])
        }
        .onChange(of: selectedSymbol) { _ in
            loadData()
        }
        .onChange(of: timeframe) { _ in
            loadData()
        }
        .onChange(of: selectedPeriod) { _ in
            loadData()
        }
        .onAppear {
            loadData()
        }
    }
    
    private func loadData() {
        Task {
            await appViewModel.realTimeMarket.loadHistoricalData(for: [selectedSymbol])
        }
    }
    
    private func calculateIndicators(for data: [CandleStickData]) -> [IndicatorData] {
        let prices = data.map { $0.close }
        var indicators: [IndicatorData] = []
        
        for type in selectedIndicators {
            let period = indicatorPeriods[type] ?? type.defaultPeriod
            
            switch type {
            case .sma:
                let values = TechnicalAnalysis.calculateSMA(prices: prices, period: period)
                let points = zip(data, values).map { IndicatorPoint(date: $0.date, value: $1) }
                indicators.append(IndicatorData(type: type, period: period, points: points))
                
            case .ema:
                let values = TechnicalAnalysis.calculateEMA(prices: prices, period: period)
                let points = zip(data, values).map { IndicatorPoint(date: $0.date, value: $1) }
                indicators.append(IndicatorData(type: type, period: period, points: points))
                
            case .rsi:
                let values = TechnicalAnalysis.calculateRSI(prices: prices, period: period)
                let points = zip(data, values).map { IndicatorPoint(date: $0.date, value: $1) }
                indicators.append(IndicatorData(type: type, period: period, points: points))
                
            case .macd:
                let (macd, signal, histogram) = TechnicalAnalysis.calculateMACD(prices: prices)
                let macdPoints = zip(data, macd).map { IndicatorPoint(date: $0.date, value: $1) }
                let signalPoints = zip(data, signal).map { IndicatorPoint(date: $0.date, value: $1) }
                let histogramPoints = zip(data, histogram).map { IndicatorPoint(date: $0.date, value: $1) }
                
                indicators.append(IndicatorData(
                    type: type,
                    period: period,
                    points: macdPoints,
                    additionalData: [
                        "Signal": signalPoints,
                        "Histogram": histogramPoints
                    ]
                ))
                
            case .bollingerBands:
                let (middle, upper, lower) = TechnicalAnalysis.calculateBollingerBands(prices: prices, period: period)
                let middlePoints = zip(data, middle).map { IndicatorPoint(date: $0.date, value: $1) }
                let upperPoints = zip(data, upper).map { IndicatorPoint(date: $0.date, value: $1) }
                let lowerPoints = zip(data, lower).map { IndicatorPoint(date: $0.date, value: $1) }
                
                indicators.append(IndicatorData(
                    type: type,
                    period: period,
                    points: middlePoints,
                    additionalData: [
                        "Upper Band": upperPoints,
                        "Lower Band": lowerPoints
                    ]
                ))
            }
        }
        
        return indicators
    }
    
    private func addAnnotation() {
        guard let lastPrice = appViewModel.realTimeMarket.lastTrades[selectedSymbol] else { return }
        
        let annotation = ChartAnnotation(
            type: newAnnotationType,
            date: Date(),
            price: lastPrice,
            text: newAnnotationText
        )
        
        annotations.append(annotation)
        newAnnotationText = ""
        showingAnnotationSheet = false
    }
}

struct IndicatorSelectionView: View {
    @Binding var selectedIndicators: Set<IndicatorType>
    @Binding var indicatorPeriods: [IndicatorType: Int]
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        List {
            ForEach(IndicatorType.allCases, id: \.self) { indicator in
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Toggle(isOn: Binding(
                            get: { selectedIndicators.contains(indicator) },
                            set: { isSelected in
                                if isSelected {
                                    selectedIndicators.insert(indicator)
                                    if indicatorPeriods[indicator] == nil {
                                        indicatorPeriods[indicator] = indicator.defaultPeriod
                                    }
                                } else {
                                    selectedIndicators.remove(indicator)
                                }
                            }
                        )) {
                            Text(indicator.rawValue)
                                .font(.headline)
                        }
                        .accessibilityLabel("\(indicator.rawValue) indicator")
                        
                        if selectedIndicators.contains(indicator) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Period")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                HStack {
                                    Slider(
                                        value: Binding(
                                            get: { Double(indicatorPeriods[indicator] ?? indicator.defaultPeriod) },
                                            set: { indicatorPeriods[indicator] = Int($0) }
                                        ),
                                        in: 2...200,
                                        step: 1
                                    )
                                    .accessibilityLabel("Adjust period")
                                    
                                    Text("\(indicatorPeriods[indicator] ?? indicator.defaultPeriod)")
                                        .monospacedDigit()
                                        .frame(width: 40)
                                }
                            }
                            .padding(.leading)
                        }
                    }
                } header: {
                    Text(indicator.description)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
            }
        }
        .listStyle(.insetGrouped)
    }
}

struct AnnotationEditorView: View {
    @Binding var type: ChartAnnotation.AnnotationType
    @Binding var text: String
    let onSave: () -> Void
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        Form {
            Section {
                Picker("Type", selection: $type) {
                    ForEach(ChartAnnotation.AnnotationType.allCases, id: \.self) { type in
                        Label(type.rawValue, systemImage: type.iconName)
                            .tag(type)
                    }
                }
                .pickerStyle(.inline)
                .accessibilityLabel("Annotation type")
            } header: {
                Text("Annotation Type")
            }
            
            Section {
                TextEditor(text: $text)
                    .frame(minHeight: 100)
                    .accessibilityLabel("Annotation text")
            } header: {
                Text("Note")
            } footer: {
                Text("Add your analysis or observations about this price point.")
                    .foregroundColor(.secondary)
            }
        }
    }
}

extension ChartAnnotation.AnnotationType {
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
        }
    }
}
