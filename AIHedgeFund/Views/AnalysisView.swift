import SwiftUI
import Charts

struct AnalysisView: View {
    @EnvironmentObject private var appViewModel: AppViewModel
    @State private var selectedTimeframe: Timeframe = .oneDay
    @State private var selectedSymbol = ""
    
    enum Timeframe: String, CaseIterable {
        case oneDay = "1D"
        case oneWeek = "1W"
        case oneMonth = "1M"
        case threeMonths = "3M"
        case oneYear = "1Y"
        case fiveYears = "5Y"
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                HStack {
                    SearchBar(text: $selectedSymbol)
                        .frame(maxWidth: 200)
                    
                    Picker("Timeframe", selection: $selectedTimeframe) {
                        ForEach(Timeframe.allCases, id: \.self) { timeframe in
                            Text(timeframe.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                .padding()
                
                TabView {
                    PriceChartView()
                        .tabItem {
                            Label("Price", systemImage: "chart.xyaxis.line")
                        }
                    
                    TechnicalIndicatorsView()
                        .tabItem {
                            Label("Technical", systemImage: "waveform.path.ecg")
                        }
                    
                    FundamentalsView()
                        .tabItem {
                            Label("Fundamentals", systemImage: "doc.text")
                        }
                    
                    AIAnalysisView()
                        .tabItem {
                            Label("AI Analysis", systemImage: "brain")
                        }
                }
            }
            .navigationTitle("Analysis")
        }
    }
}

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search Symbol", text: $text)
                .textFieldStyle(.roundedBorder)
        }
    }
}

struct PriceChartView: View {
    var body: some View {
        GroupBox {
            Chart {
                // Add chart data here
            }
            .frame(height: 400)
        }
        .padding()
    }
}

struct TechnicalIndicatorsView: View {
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                TechnicalIndicatorCard(title: "Moving Averages", value: "Bullish")
                TechnicalIndicatorCard(title: "RSI", value: "65.5")
                TechnicalIndicatorCard(title: "MACD", value: "Bearish")
                TechnicalIndicatorCard(title: "Bollinger Bands", value: "Upper: 155.00")
            }
            .padding()
        }
    }
}

struct TechnicalIndicatorCard: View {
    let title: String
    let value: String
    
    var body: some View {
        GroupBox(title) {
            Text(value)
                .font(.headline)
                .padding()
        }
    }
}

struct FundamentalsView: View {
    var body: some View {
        List {
            Section("Key Statistics") {
                InfoRow(label: "Market Cap", value: "$2.5T")
                InfoRow(label: "P/E Ratio", value: "28.5")
                InfoRow(label: "Dividend Yield", value: "0.65%")
                InfoRow(label: "52-Week High", value: "$180.00")
                InfoRow(label: "52-Week Low", value: "$120.00")
            }
            
            Section("Financial Ratios") {
                InfoRow(label: "Quick Ratio", value: "1.2")
                InfoRow(label: "Debt/Equity", value: "1.5")
                InfoRow(label: "ROE", value: "35%")
                InfoRow(label: "Profit Margin", value: "25%")
            }
        }
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Text(value)
                .foregroundColor(.secondary)
        }
    }
}

struct AIAnalysisView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                GroupBox("AI Sentiment Analysis") {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Overall Sentiment: Bullish")
                            .font(.headline)
                        Text("Confidence Score: 85%")
                        Text("Based on analysis of recent news, social media sentiment, and technical indicators.")
                            .font(.caption)
                    }
                    .padding()
                }
                
                GroupBox("Price Prediction") {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("1-Month Target: $165.00")
                        Text("3-Month Target: $175.00")
                        Text("6-Month Target: $190.00")
                    }
                    .padding()
                }
                
                GroupBox("Risk Analysis") {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Risk Level: Moderate")
                            .font(.headline)
                        Text("• High market volatility expected")
                        Text("• Strong fundamental indicators")
                        Text("• Positive industry trends")
                    }
                    .padding()
                }
            }
            .padding()
        }
    }
}

struct AnalysisView_Previews: PreviewProvider {
    static var previews: some View {
        AnalysisView()
            .environmentObject(AppViewModel())
    }
}
