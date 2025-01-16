import Vapor
import Foundation

struct StockController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let stocks = routes.grouped("api", "stocks")
        
        stocks.get(":symbol", "bars") { req -> EventLoopFuture<ClientResponse> in
            guard let symbol = req.parameters.get("symbol") else {
                throw Abort(.badRequest, reason: "Symbol is required")
            }
            
            let timeframe = req.query[String.self, at: "timeframe"] ?? "1Day"
            
            // Construct Alpaca API URL
            let baseURL = "https://data.alpaca.markets/v2"
            let endpoint = "/stocks/\(symbol)/bars"
            
            guard var urlComponents = URLComponents(string: baseURL + endpoint) else {
                throw Abort(.internalServerError, reason: "Invalid URL")
            }
            
            // Get current date and date 30 days ago
            let end = Date()
            let start = Calendar.current.date(byAdding: .day, value: -30, to: end) ?? end
            
            let dateFormatter = ISO8601DateFormatter()
            dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            
            urlComponents.queryItems = [
                URLQueryItem(name: "timeframe", value: timeframe),
                URLQueryItem(name: "start", value: dateFormatter.string(from: start)),
                URLQueryItem(name: "end", value: dateFormatter.string(from: end)),
                URLQueryItem(name: "limit", value: "100")
            ]
            
            guard let urlString = urlComponents.string else {
                throw Abort(.internalServerError, reason: "Invalid URL")
            }
            
            // Add Alpaca API keys from environment
            guard let apiKeyID = Environment.get("ALPACA_KEY_ID"),
                  let secretKey = Environment.get("ALPACA_SECRET_KEY") else {
                throw Abort(.internalServerError, reason: "Missing Alpaca API credentials")
            }
            
            // Create headers
            var headers = HTTPHeaders()
            headers.add(name: "APCA-API-KEY-ID", value: apiKeyID)
            headers.add(name: "APCA-API-SECRET-KEY", value: secretKey)
            headers.add(name: "Accept", value: "application/json")
            
            return req.client.get(URI(string: urlString), headers: headers)
        }
    }
}

struct Bar: Content {
    let timestamp: Date
    let open: Double
    let high: Double
    let low: Double
    let close: Double
    let volume: Int
    let vwap: Double?
    let tradeCount: Int?
}
