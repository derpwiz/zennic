import Foundation

/// Response model for bar data from Alpaca API
struct BarsResponse: Codable {
    let bars: [StockBarData]
    let symbol: String
    let nextPageToken: String?
    
    private enum CodingKeys: String, CodingKey {
        case bars
        case symbol
        case nextPageToken = "next_page_token"
    }
}
