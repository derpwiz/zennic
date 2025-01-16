// Import required frameworks for UI and charting functionality
import SwiftUI

/// Main view for stock analysis functionality
/// Provides comprehensive analysis tools including price charts, technical indicators,
/// fundamentals data, and AI-powered analysis
struct AnalysisView: View {
    @EnvironmentObject private var appViewModel: AppViewModel
    @State private var selectedTimeframe: Timeframe = .oneDay
    @State private var selectedSymbol = ""
    
    /// Timeframe options for analysis charts and data
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
                    /// Custom search bar component for symbol lookup
                    SearchBar(text: $selectedSymbol)
                        .frame(maxWidth: 200)
                    
                    /// Picker for selecting timeframe
                    Picker("Timeframe", selection: $selectedTimeframe) {
                        ForEach(Timeframe.allCases, id: \.self) { timeframe in
                            Text(timeframe.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                .padding()
                
                /// Tab view for switching between different analysis tools
                TabView {
                    /// View component for displaying price charts
                    PriceChartView()
                        .tabItem {
                            Label("Price", systemImage: "chart.xyaxis.line")
                        }
                    
                    /// View displaying various technical indicators in a grid layout
                    TechnicalIndicatorsView()
                        .tabItem {
                            Label("Technical", systemImage: "waveform.path.ecg")
                        }
                    
                    /// View displaying fundamental financial data
                    FundamentalsView()
                        .tabItem {
                            Label("Fundamentals", systemImage: "doc.text")
                        }
                    
                    /// View providing AI-powered market analysis and predictions
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

/// Custom search bar component for symbol lookup
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

/// View component for displaying price charts
struct PriceChartView: View {
    var body: some View {
        GroupBox {
            Text("Price Chart Coming Soon")
                .frame(height: 400)
        }
        .padding()
    }
}

/// View displaying various technical indicators in a grid layout
struct TechnicalIndicatorsView: View {
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                /// Reusable card component for displaying technical indicators
                TechnicalIndicatorCard(title: "Moving Averages", value: "Bullish")
                TechnicalIndicatorCard(title: "RSI", value: "65.5")
                TechnicalIndicatorCard(title: "MACD", value: "Bearish")
                TechnicalIndicatorCard(title: "Bollinger Bands", value: "Upper: 155.00")
            }
            .padding()
        }
    }
}

/// Reusable card component for displaying technical indicators
struct TechnicalIndicatorCard: View {
    let title: String    // Name of the technical indicator
    let value: String    // Current value or status of the indicator
    
    var body: some View {
        GroupBox(title) {
            Text(value)
                .font(.headline)
                .padding()
        }
    }
}

/// View displaying fundamental financial data
struct FundamentalsView: View {
    var body: some View {
        List {
            Section("Key Statistics") {
                /// Reusable row component for displaying key-value information
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

/// Reusable row component for displaying key-value information
struct InfoRow: View {
    let label: String    // Description of the financial metric
    let value: String    // Value of the financial metric
    
    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Text(value)
                .foregroundColor(.secondary)
        }
    }
}

/// View providing AI-powered market analysis and predictions
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

/// Preview provider for SwiftUI canvas
struct AnalysisView_Previews: PreviewProvider {
    static var previews: some View {
        AnalysisView()
            .environmentObject(AppViewModel())
    }
}
