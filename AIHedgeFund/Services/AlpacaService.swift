import Foundation
import os

@MainActor
final class AlpacaService {
    static let shared = AlpacaService()
    private let alpacaBaseURL = "https://api.alpaca.markets"
    private let backendBaseURL = "http://localhost:8080"
    private let session: URLSession
    private let logger = Logger(subsystem: "com.aihedgefund.app", category: "AlpacaService")
    private let userDefaults = UserDefaults.standard
    
    private init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 300
        self.session = URLSession(configuration: configuration)
        logger.info("AlpacaService initialized")
    }
    
    func saveAlpacaKeys(_ keys: AppModels.AlpacaKeysCreate) async throws -> AppModels.AlpacaKeysResponse {
        let urlString = "\(alpacaBaseURL)/v2/account"
        logger.info("Validating Alpaca keys: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            logger.error("Invalid URL: \(urlString)")
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(keys.apiKey, forHTTPHeaderField: "APCA-API-KEY-ID")
        request.setValue(keys.secretKey, forHTTPHeaderField: "APCA-API-SECRET-KEY")
        request.timeoutInterval = 30
        
        let (data, httpResponse) = try await session.data(for: request)
        
        guard let httpResponse = httpResponse as? HTTPURLResponse else {
            logger.error("Invalid response type")
            throw URLError(.badServerResponse)
        }
        
        if httpResponse.statusCode == 401 {
            logger.error("Invalid Alpaca credentials")
            throw APIError.invalidCredentials
        }
        
        guard httpResponse.statusCode == 200 else {
            if let errorData = try? JSONDecoder().decode(AppModels.ErrorResponse.self, from: data) {
                logger.error("Server error: \(errorData.reason)")
                throw APIError.serverError(message: errorData.reason)
            }
            logger.error("Server error: status code \(httpResponse.statusCode)")
            throw APIError.serverError(message: "Server returned status code \(httpResponse.statusCode)")
        }
        
        // If we get here, the keys are valid. Now save them to our backend
        let backendURL = URL(string: "\(backendBaseURL)/users/alpaca-keys")!
        var backendRequest = URLRequest(url: backendURL)
        backendRequest.httpMethod = "POST"
        backendRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = userDefaults.string(forKey: "authToken") {
            backendRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            logger.info("Added auth token to request")
        } else {
            logger.warning("No auth token found")
            throw APIError.unauthorized
        }
        
        let encoder = JSONEncoder()
        backendRequest.httpBody = try encoder.encode(keys)
        
        let (backendData, backendResponse) = try await session.data(for: backendRequest)
        
        guard let backendResponse = backendResponse as? HTTPURLResponse else {
            logger.error("Invalid backend response type")
            throw URLError(.badServerResponse)
        }
        
        if backendResponse.statusCode == 401 {
            logger.error("Unauthorized request to backend")
            throw APIError.unauthorized
        }
        
        guard backendResponse.statusCode == 200 else {
            if let errorData = try? JSONDecoder().decode(AppModels.ErrorResponse.self, from: backendData) {
                logger.error("Backend error: \(errorData.reason)")
                throw APIError.serverError(message: errorData.reason)
            }
            logger.error("Backend error: status code \(backendResponse.statusCode)")
            throw APIError.serverError(message: "Backend returned status code \(backendResponse.statusCode)")
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let keysResponse = try decoder.decode(AppModels.AlpacaKeysResponse.self, from: backendData)
        logger.info("Successfully saved Alpaca keys")
        return keysResponse
    }
    
    func getAlpacaKeys() async throws -> AppModels.AlpacaKeysResponse {
        let urlString = "\(backendBaseURL)/users/alpaca-keys"
        logger.info("Fetching Alpaca keys: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            logger.error("Invalid URL: \(urlString)")
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 30
        
        if let token = userDefaults.string(forKey: "authToken") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            logger.info("Added auth token to request")
        } else {
            logger.warning("No auth token found")
            throw APIError.unauthorized
        }
        
        let (data, httpResponse) = try await session.data(for: request)
        
        guard let httpResponse = httpResponse as? HTTPURLResponse else {
            logger.error("Invalid response type")
            throw URLError(.badServerResponse)
        }
        
        if httpResponse.statusCode == 401 {
            logger.error("Unauthorized request")
            throw APIError.unauthorized
        }
        
        guard httpResponse.statusCode == 200 else {
            if let errorData = try? JSONDecoder().decode(AppModels.ErrorResponse.self, from: data) {
                logger.error("Server error: \(errorData.reason)")
                throw APIError.serverError(message: errorData.reason)
            }
            logger.error("Server error: status code \(httpResponse.statusCode)")
            throw APIError.serverError(message: "Server returned status code \(httpResponse.statusCode)")
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let keysResponse = try decoder.decode(AppModels.AlpacaKeysResponse.self, from: data)
        logger.info("Successfully fetched Alpaca keys")
        return keysResponse
    }
    
    func deleteAlpacaKeys() async throws {
        let urlString = "\(backendBaseURL)/users/alpaca-keys"
        logger.info("Deleting Alpaca keys: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            logger.error("Invalid URL: \(urlString)")
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.timeoutInterval = 30
        
        if let token = userDefaults.string(forKey: "authToken") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            logger.info("Added auth token to request")
        } else {
            logger.warning("No auth token found")
            throw APIError.unauthorized
        }
        
        let (_, httpResponse) = try await session.data(for: request)
        
        guard let httpResponse = httpResponse as? HTTPURLResponse else {
            logger.error("Invalid response type")
            throw URLError(.badServerResponse)
        }
        
        if httpResponse.statusCode == 401 {
            logger.error("Unauthorized request")
            throw APIError.unauthorized
        }
        
        guard httpResponse.statusCode == 200 else {
            if let errorData = try? JSONDecoder().decode(AppModels.ErrorResponse.self, from: Data()) {
                logger.error("Server error: \(errorData.reason)")
                throw APIError.serverError(message: errorData.reason)
            }
            logger.error("Server error: status code \(httpResponse.statusCode)")
            throw APIError.serverError(message: "Server returned status code \(httpResponse.statusCode)")
        }
        
        logger.info("Successfully deleted Alpaca keys")
    }
    
    func fetchBarData(symbol: String, timeframe: String = "1Day", limit: Int = 100) async throws -> [StockBarData] {
        let urlString = "\(backendBaseURL)/market/bars?symbol=\(symbol)&timeframe=\(timeframe)&limit=\(limit)"
        logger.info("Fetching bar data: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            logger.error("Invalid URL: \(urlString)")
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 30
        
        if let token = userDefaults.string(forKey: "authToken") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            logger.info("Added auth token to request")
        } else {
            logger.warning("No auth token found")
        }
        
        do {
            let (data, httpResponse) = try await session.data(for: request)
            
            guard let httpResponse = httpResponse as? HTTPURLResponse else {
                logger.error("Invalid response type")
                throw URLError(.badServerResponse)
            }
            
            if httpResponse.statusCode == 401 {
                logger.error("Unauthorized request")
                throw APIError.unauthorized
            }
            
            guard httpResponse.statusCode == 200 else {
                if let errorData = try? JSONDecoder().decode(AppModels.ErrorResponse.self, from: data) {
                    logger.error("Server error: \(errorData.reason)")
                    throw APIError.serverError(message: errorData.reason)
                }
                logger.error("Server error: status code \(httpResponse.statusCode)")
                throw APIError.serverError(message: "Server returned status code \(httpResponse.statusCode)")
            }
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            // First try to decode as a direct array
            do {
                let bars = try decoder.decode([StockBarData].self, from: data)
                logger.info("Successfully decoded \(bars.count) bars directly")
                return bars
            } catch {
                // If direct decoding fails, try decoding as a wrapper object
                struct BarsResponse: Codable {
                    let bars: [StockBarData]
                }
                
                let barsResponse = try decoder.decode(BarsResponse.self, from: data)
                logger.info("Successfully decoded \(barsResponse.bars.count) bars from wrapper")
                return barsResponse.bars
            }
        } catch {
            logger.error("Network error: \(error.localizedDescription)")
            throw APIError.serverError(message: error.localizedDescription)
        }
    }
}
