import Foundation
import Combine

class MarketDataService {
    private let apiKey: String
    private let session: URLSession
    private let baseURL = "https://www.alphavantage.co/query"
    
    init(apiKey: String, session: URLSession = .shared) {
        self.apiKey = apiKey
        self.session = session
    }
    
    func fetchStockPrice(symbol: String) -> AnyPublisher<Double, Error> {
        let queryItems = [
            URLQueryItem(name: "function", value: "GLOBAL_QUOTE"),
            URLQueryItem(name: "symbol", value: symbol),
            URLQueryItem(name: "apikey", value: apiKey)
        ]
        
        var components = URLComponents(string: baseURL)!
        components.queryItems = queryItems
        
        let request = URLRequest(url: components.url!)
        
        return session.dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: GlobalQuoteResponse.self, decoder: JSONDecoder())
            .map { Double($0.globalQuote.price) ?? 0.0 }
            .eraseToAnyPublisher()
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
