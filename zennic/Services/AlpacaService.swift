import Foundation
import Combine
import os

/// Service class for interacting with the Alpaca trading API
class AlpacaService {
    private var session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    
    /// Base URLs for the Alpaca API
    private let tradingBaseURL = "https://api.alpaca.markets"
    private let dataBaseURL = "https://data.alpaca.markets"
    
    /// API credentials
    private var apiKey: String {
        didSet {
            UserDefaults.standard.set(apiKey, forKey: "ALPACA_API_KEY")
        }
    }
    private var secretKey: String {
        didSet {
            UserDefaults.standard.set(secretKey, forKey: "ALPACA_API_SECRET")
        }
    }
    
    /// Initializes the AlpacaService with API credentials
    /// - Parameters:
    ///   - apiKey: Alpaca API key
    ///   - secretKey: Alpaca API secret
    init(apiKey: String, secretKey: String) {
        self.apiKey = apiKey
        self.secretKey = secretKey
        
        let configuration = URLSessionConfiguration.default
        configuration.httpAdditionalHeaders = [
            "APCA-API-KEY-ID": apiKey,
            "APCA-API-SECRET-KEY": secretKey
        ]
        
        self.session = URLSession(configuration: configuration)
        self.decoder = JSONDecoder()
        self.encoder = JSONEncoder()
        
        // Configure date decoding strategy
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        decoder.dateDecodingStrategy = .formatted(dateFormatter)
    }
    
    /// Updates the API credentials
    /// - Parameters:
    ///   - apiKey: New API key
    ///   - secretKey: New API secret
    func updateCredentials(apiKey: String, secretKey: String) {
        self.apiKey = apiKey
        self.secretKey = secretKey
        
        let configuration = URLSessionConfiguration.default
        configuration.httpAdditionalHeaders = [
            "APCA-API-KEY-ID": apiKey,
            "APCA-API-SECRET-KEY": secretKey
        ]
        // Update the session with new configuration
        self.session = URLSession(configuration: configuration)
    }
    
    /// Validates the API credentials by attempting to fetch account information
    /// - Returns: A publisher that emits a boolean indicating if the credentials are valid
    func validateCredentials() -> AnyPublisher<Bool, Error> {
        let url = URL(string: "\(tradingBaseURL)/v2/account")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw APIError.invalidResponse
                }
                
                if httpResponse.statusCode == 200 {
                    return true
                } else if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
                    return false
                } else {
                    throw APIError.httpError(statusCode: httpResponse.statusCode)
                }
            }
            .eraseToAnyPublisher()
    }
    
    /// Submits a new order to Alpaca
    /// - Parameters:
    ///   - symbol: The stock symbol
    ///   - qty: Quantity of shares
    ///   - side: Buy or sell
    ///   - type: Market, limit, etc.
    ///   - timeInForce: Day, GTC, etc.
    ///   - limitPrice: Optional limit price for limit orders
    /// - Returns: A publisher that emits the created order
    func submitOrder(symbol: String,
                    qty: Double,
                    side: OrderSide,
                    type: OrderType,
                    timeInForce: TimeInForce,
                    limitPrice: Double? = nil) -> AnyPublisher<AlpacaOrder, Error> {
        let url = URL(string: "\(tradingBaseURL)/v2/orders")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        var orderData: [String: Any] = [
            "symbol": symbol,
            "qty": String(qty),
            "side": side.rawValue,
            "type": type.rawValue,
            "time_in_force": timeInForce.rawValue
        ]
        
        if let limitPrice = limitPrice {
            orderData["limit_price"] = String(limitPrice)
        }
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: orderData)
        } catch {
            return Fail(error: error).eraseToAnyPublisher()
        }
        
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw APIError.invalidResponse
                }
                
                if httpResponse.statusCode != 200 {
                    throw APIError.httpError(statusCode: httpResponse.statusCode)
                }
                
                return data
            }
            .decode(type: AlpacaOrder.self, decoder: decoder)
            .eraseToAnyPublisher()
    }
    
    /// Retrieves all open orders
    /// - Returns: A publisher that emits an array of open orders
    func getOpenOrders() -> AnyPublisher<[AlpacaOrder], Error> {
        let url = URL(string: "\(tradingBaseURL)/v2/orders")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw APIError.invalidResponse
                }
                
                if httpResponse.statusCode != 200 {
                    throw APIError.httpError(statusCode: httpResponse.statusCode)
                }
                
                return data
            }
            .decode(type: [AlpacaOrder].self, decoder: decoder)
            .eraseToAnyPublisher()
    }
    
    /// Cancels an open order
    /// - Parameter orderId: The ID of the order to cancel
    /// - Returns: A publisher that completes when the order is cancelled
    func cancelOrder(orderId: String) -> AnyPublisher<Void, Error> {
        let url = URL(string: "\(tradingBaseURL)/v2/orders/\(orderId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw APIError.invalidResponse
                }
                
                if httpResponse.statusCode != 204 {
                    throw APIError.httpError(statusCode: httpResponse.statusCode)
                }
            }
            .eraseToAnyPublisher()
    }
    
    /// Retrieves account information
    /// - Returns: A publisher that emits the account information
    func getAccount() -> AnyPublisher<AlpacaAccount, Error> {
        let url = URL(string: "\(tradingBaseURL)/v2/account")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw APIError.invalidResponse
                }
                
                if httpResponse.statusCode != 200 {
                    throw APIError.httpError(statusCode: httpResponse.statusCode)
                }
                
                return data
            }
            .decode(type: AlpacaAccount.self, decoder: decoder)
            .eraseToAnyPublisher()
    }
    
    /// Retrieves all positions
    /// - Returns: A publisher that emits an array of positions
    func getPositions() -> AnyPublisher<[AlpacaPosition], Error> {
        let url = URL(string: "\(tradingBaseURL)/v2/positions")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw APIError.invalidResponse
                }
                
                if httpResponse.statusCode != 200 {
                    throw APIError.httpError(statusCode: httpResponse.statusCode)
                }
                
                return data
            }
            .decode(type: [AlpacaPosition].self, decoder: decoder)
            .eraseToAnyPublisher()
    }
    
    /// Retrieves bar data for a symbol
    /// - Parameters:
    ///   - symbol: The stock symbol
    ///   - timeframe: Timeframe for the bars (e.g., "1Min", "5Min", "1Day")
    ///   - limit: Maximum number of bars to return (default: 100)
    /// - Returns: Array of stock bar data
    func fetchBarData(symbol: String, timeframe: String = "1Day", limit: Int = 100) async throws -> [StockBarData] {
        let url = URL(string: "\(dataBaseURL)/v2/stocks/\(symbol)/bars")!
        var components = URLComponents(url: url, resolvingAgainstBaseURL: true)!
        components.queryItems = [
            URLQueryItem(name: "timeframe", value: timeframe),
            URLQueryItem(name: "limit", value: String(limit))
        ]
        
        var request = URLRequest(url: components.url!)
        request.httpMethod = "GET"
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        if httpResponse.statusCode != 200 {
            throw APIError.httpError(statusCode: httpResponse.statusCode)
        }
        
        let barsResponse = try decoder.decode(BarsResponse.self, from: data)
        return barsResponse.bars
    }
    
    /// Gets the stored Alpaca API keys
    /// - Returns: The stored API keys or nil if not found
    func getAlpacaKeys() async throws -> AlpacaKeys? {
        guard !apiKey.isEmpty && !secretKey.isEmpty else {
            return nil
        }
        
        return AlpacaKeys(
            apiKey: apiKey,
            apiSecret: secretKey,
            isPaperTrading: true // Default to paper trading for safety
        )
    }
    
    /// Saves the Alpaca API keys
    /// - Parameter keys: The API keys to save
    func saveAlpacaKeys(_ keys: AlpacaKeysCreate) async throws {
        // Create a new service instance for validation
        let validationService = AlpacaService(apiKey: keys.apiKey, secretKey: keys.apiSecret)
        
        // Validate the keys
        do {
            let isValid = try await validationService.validateCredentials().async()
            guard isValid else {
                throw APIError.invalidCredentials
            }
            
            // Update credentials only after successful validation
            self.apiKey = keys.apiKey
            self.secretKey = keys.apiSecret
            updateCredentials(apiKey: keys.apiKey, secretKey: keys.apiSecret)
        } catch {
            throw APIError.invalidCredentials
        }
    }
    
    /// Deletes the stored Alpaca API keys
    func deleteAlpacaKeys() async throws {
        UserDefaults.standard.removeObject(forKey: "ALPACA_API_KEY")
        UserDefaults.standard.removeObject(forKey: "ALPACA_API_SECRET")
        
        self.apiKey = ""
        self.secretKey = ""
        updateCredentials(apiKey: "", secretKey: "")
    }
    
    /// Authenticates with Alpaca using the current API keys
    func authenticateWithAlpaca() async throws {
        let isValid = try await validateCredentials().async()
        guard isValid else {
            throw APIError.authenticationFailed
        }
    }
    
    /// Shared instance for singleton access
    static let shared: AlpacaService = {
        // Use environment variables or fallback to stored keys
        let apiKey = ProcessInfo.processInfo.environment["ALPACA_API_KEY"] ?? 
                    UserDefaults.standard.string(forKey: "ALPACA_API_KEY") ?? ""
        let secretKey = ProcessInfo.processInfo.environment["ALPACA_API_SECRET"] ?? 
                       UserDefaults.standard.string(forKey: "ALPACA_API_SECRET") ?? ""
        return AlpacaService(apiKey: apiKey, secretKey: secretKey)
    }()
}

// MARK: - Combine Async/Await Extensions

extension Publisher {
    func async() async throws -> Output {
        try await withCheckedThrowingContinuation { continuation in
            var cancellable: AnyCancellable?
            
            cancellable = self
                .sink(
                    receiveCompletion: { completion in
                        switch completion {
                        case .finished:
                            break
                        case .failure(let error):
                            continuation.resume(throwing: error)
                        }
                        cancellable?.cancel()
                    },
                    receiveValue: { value in
                        continuation.resume(returning: value)
                        cancellable?.cancel()
                    }
                )
        }
    }
}
