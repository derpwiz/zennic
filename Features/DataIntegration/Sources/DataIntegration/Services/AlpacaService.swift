import Foundation

public class DataIntegration_AlpacaService {
    public let accessToken: String
    private let baseURL = "https://paper-api.alpaca.markets"
    
    public init(accessToken: String) {
        self.accessToken = accessToken
    }
    
    // MARK: - API Calls
    
    public func getAccount() async throws -> [String: Any] {
        let endpoint = "/v2/account"
        return try await sendRequest(to: endpoint, method: "GET") as! [String: Any]
    }
    
    public func getPositions() async throws -> [[String: Any]] {
        let endpoint = "/v2/positions"
        return try await sendRequest(to: endpoint, method: "GET") as! [[String: Any]]
    }
    
    public func getMarketData(symbol: String, timeframe: String) async throws -> [String: Any] {
        let endpoint = "/v2/stocks/\(symbol)/bars"
        let queryItems = [
            URLQueryItem(name: "timeframe", value: timeframe)
        ]
        return try await sendRequest(to: endpoint, method: "GET", queryItems: queryItems) as! [String: Any]
    }
    
    // MARK: - Helper Methods
    
    private func sendRequest(to endpoint: String, method: String, queryItems: [URLQueryItem]? = nil) async throws -> Any {
        guard var urlComponents = URLComponents(string: baseURL + endpoint) else {
            throw NSError(domain: "AlpacaService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        urlComponents.queryItems = queryItems
        
        guard let url = urlComponents.url else {
            throw NSError(domain: "AlpacaService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, 200...299 ~= httpResponse.statusCode else {
            throw NSError(domain: "AlpacaService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        return try JSONSerialization.jsonObject(with: data, options: [])
    }
}
