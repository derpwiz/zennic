import Foundation
import Combine

enum MarketDataError: Error {
    case invalidResponse
    case invalidPrice
    case rateLimitExceeded
    case apiError(String)
}

@MainActor
final class MarketDataService {
    private let apiKey: String
    private let session: URLSession
    private let baseURL = "https://www.alphavantage.co/query"
    private var lastRequestTime: Date?
    private let minimumRequestInterval: TimeInterval = 12.0 // Alpha Vantage free tier limit
    
    var hasValidAPIKey: Bool {
        !apiKey.isEmpty
    }
    
    init(apiKey: String, session: URLSession = .shared) {
        self.apiKey = apiKey
        self.session = session
    }
    
    func fetchStockPrice(symbol: String) -> AnyPublisher<Double, Error> {
        guard canMakeRequest() else {
            return Fail(error: MarketDataError.rateLimitExceeded).eraseToAnyPublisher()
        }
        
        let queryItems = [
            URLQueryItem(name: "function", value: "GLOBAL_QUOTE"),
            URLQueryItem(name: "symbol", value: symbol),
            URLQueryItem(name: "apikey", value: apiKey)
        ]
        
        var components = URLComponents(string: baseURL)!
        components.queryItems = queryItems
        
        let request = URLRequest(url: components.url!)
        lastRequestTime = Date()
        
        return session.dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: GlobalQuoteResponse.self, decoder: JSONDecoder())
            .tryMap { response in
                guard let price = Double(response.globalQuote.price) else {
                    throw MarketDataError.invalidPrice
                }
                return price
            }
            .mapError { error in
                if let marketError = error as? MarketDataError {
                    return marketError
                }
                return MarketDataError.apiError(error.localizedDescription)
            }
            .eraseToAnyPublisher()
    }
    
    private func canMakeRequest() -> Bool {
        guard let lastRequest = lastRequestTime else { return true }
        return Date().timeIntervalSince(lastRequest) >= minimumRequestInterval
    }
}

struct GlobalQuoteResponse: Codable {
    let globalQuote: GlobalQuote
    
    enum CodingKeys: String, CodingKey {
        case globalQuote = "Global Quote"
    }
}

struct GlobalQuote: Codable {
    let price: String
    
    enum CodingKeys: String, CodingKey {
        case price = "05. price"
    }
}
