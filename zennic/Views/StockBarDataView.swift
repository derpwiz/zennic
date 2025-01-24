import SwiftUI
import Charts

/// Extension to provide chart-related UI components for StockBarData
extension StockBarData {
    /// The color of the candle based on price movement
    var candleColor: Color {
        closePrice >= openPrice ? Color.green.opacity(0.8) : Color.red.opacity(0.8)
    }
    
    /// The width of the candle body
    private static let candleWidth: CGFloat = 6
    
    /// The width of the wick line
    private static let wickWidth: CGFloat = 1
    
    /// Creates a view for the wick (high/low) line of the candlestick
    var wickLine: some View {
        Path { path in
            let x = 0.0
            path.move(to: CGPoint(x: x, y: highPrice))
            path.addLine(to: CGPoint(x: x, y: lowPrice))
        }
        .stroke(
            candleColor,
            style: StrokeStyle(
                lineWidth: Self.wickWidth,
                lineCap: .round
            )
        )
        .animation(.easeInOut, value: highPrice)
        .animation(.easeInOut, value: lowPrice)
        .accessibilityHidden(true) // Hidden because the parent view provides accessibility
    }
    
    /// Creates a view for the body (open/close) rectangle of the candlestick
    var candleRect: some View {
        Rectangle()
            .fill(candleColor)
            .frame(width: Self.candleWidth)
            .frame(height: abs(closePrice - openPrice))
            .offset(y: (closePrice - openPrice) / 2)
            .animation(.easeInOut, value: closePrice)
            .animation(.easeInOut, value: openPrice)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Candlestick")
            .accessibilityValue("""
                Open: \(formatPrice(openPrice)),
                Close: \(formatPrice(closePrice)),
                High: \(formatPrice(highPrice)),
                Low: \(formatPrice(lowPrice))
                """)
    }
    
    /// Creates a complete candlestick view combining the wick and body
    var candlestickView: some View {
        ZStack {
            wickLine
            candleRect
        }
        .compositingGroup() // Ensures proper rendering of overlapping elements
        .animation(.easeInOut, value: closePrice)
    }
    
}

// MARK: - Preview

#if DEBUG
struct StockBarDataView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleData = StockBarData(
            symbol: "AAPL",
            timestamp: Date(),
            openPrice: 150.0,
            highPrice: 155.0,
            lowPrice: 148.0,
            closePrice: 152.0,
            volume: 1000000
        )
        
        return VStack(spacing: 20) {
            // Bullish candle
            sampleData.candlestickView
                .frame(height: 100)
            
            // Bearish candle
            StockBarData(
                symbol: "AAPL",
                timestamp: Date(),
                openPrice: 150.0,
                highPrice: 152.0,
                lowPrice: 145.0,
                closePrice: 147.0,
                volume: 1000000
            )
            .candlestickView
            .frame(height: 100)
        }
        .padding()
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Candlestick Previews")
    }
}
#endif
