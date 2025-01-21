import Foundation
import os
import AuthenticationServices

@MainActor
final class AlpacaService: NSObject, ASWebAuthenticationPresentationContextProviding {
    static let shared = AlpacaService()
    private let alpacaBaseURL = "https://api.alpaca.markets"
    private let backendBaseURL = "http://localhost:8080"
    private let session: URLSession
    private let logger = Logger(subsystem: "com.zennic.app", category: "AlpacaService")
    private let userDefaults = UserDefaults.standard
    
    // OAuth configuration
    private let clientId = "YOUR_ALPACA_CLIENT_ID"  // Replace with your actual client ID
    private let clientSecret = "YOUR_ALPACA_CLIENT_SECRET"  // Replace with your actual client secret
    private let redirectUri = "zennic://oauth/callback"
    private let oauthBaseURL = "https://app.alpaca.markets/oauth"
    
    private override init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 300
        self.session = URLSession(configuration: configuration)
        super.init()
        logger.info("AlpacaService initialized")
    }
    
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        guard let window = NSApplication.shared.windows.first else {
            fatalError("No window available for auth presentation")
        }
        return window
    }
    
    func authenticateWithAlpaca() async throws -> AppModels.AlpacaOAuthResponse {
        return try await withCheckedThrowingContinuation { continuation in
            let oauthRequest = AppModels.AlpacaOAuthRequest(
                clientId: clientId,
                redirectUri: redirectUri,
                responseType: "code",
                scope: "trading account:write trading:write data"
            )
            
            let queryItems = [
                URLQueryItem(name: "client_id", value: oauthRequest.clientId),
                URLQueryItem(name: "redirect_uri", value: oauthRequest.redirectUri),
                URLQueryItem(name: "response_type", value: oauthRequest.responseType),
                URLQueryItem(name: "scope", value: oauthRequest.scope)
            ]
            
            var urlComponents = URLComponents(string: "\(oauthBaseURL)/authorize")!
            urlComponents.queryItems = queryItems
            
            let authSession = ASWebAuthenticationSession(
                url: urlComponents.url!,
                callbackURLScheme: "zennic"
            ) { callbackURL, error in
                if let error = error {
                    self.logger.error("OAuth error: \(error.localizedDescription)")
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let callbackURL = callbackURL,
                      let components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false),
                      let code = components.queryItems?.first(where: { $0.name == "code" })?.value
                else {
                    self.logger.error("Invalid callback URL or missing authorization code")
                    continuation.resume(throwing: APIError.invalidResponse)
                    return
                }
                
                // Exchange the authorization code for an access token
                Task {
                    do {
                        let tokenResponse = try await self.exchangeCodeForToken(code: code)
                        continuation.resume(returning: tokenResponse)
                    } catch {
                        self.logger.error("Token exchange error: \(error.localizedDescription)")
                        continuation.resume(throwing: error)
                    }
                }
            }
            
            authSession.presentationContextProvider = self
            authSession.prefersEphemeralWebBrowserSession = true
            
            if !authSession.start() {
                self.logger.error("Failed to start OAuth session")
                continuation.resume(throwing: APIError.authenticationFailed)
            }
        }
    }
    
    private func exchangeCodeForToken(code: String) async throws -> AppModels.AlpacaOAuthResponse {
        guard let url = URL(string: "\(oauthBaseURL)/token") else {
            logger.error("Invalid token URL")
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let bodyParams = [
            "grant_type": "authorization_code",
            "code": code,
            "client_id": clientId,
            "client_secret": clientSecret,
            "redirect_uri": redirectUri
        ]
        
        let bodyString = bodyParams
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: "&")
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        request.httpBody = bodyString.data(using: .utf8)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            logger.error("Invalid response type")
            throw URLError(.badServerResponse)
        }
        
        guard httpResponse.statusCode == 200 else {
            if let errorResponse = try? JSONDecoder().decode(AppModels.AlpacaOAuthError.self, from: data) {
                logger.error("OAuth error: \(errorResponse.error) - \(errorResponse.errorDescription)")
                throw APIError.serverError(message: errorResponse.errorDescription)
            }
            logger.error("Server error: status code \(httpResponse.statusCode)")
            throw APIError.serverError(message: "Server returned status code \(httpResponse.statusCode)")
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(AppModels.AlpacaOAuthResponse.self, from: data)
    }
    
    private func getValidAccessToken() async throws -> String {
        // Check if we have a valid token
        if let expirationDate = userDefaults.object(forKey: "alpacaTokenExpiration") as? Date,
           let accessToken = userDefaults.string(forKey: "alpacaAccessToken"),
           expirationDate > Date().addingTimeInterval(300) { // Add 5-minute buffer
            return accessToken
        }
        
        // If not, authenticate again
        let oauthResponse = try await authenticateWithAlpaca()
        userDefaults.set(oauthResponse.accessToken, forKey: "alpacaAccessToken")
        userDefaults.set(Date().addingTimeInterval(TimeInterval(oauthResponse.expiresIn)), forKey: "alpacaTokenExpiration")
        return oauthResponse.accessToken
    }
    
    private func addAuthHeaders(_ request: inout URLRequest) async throws {
        let accessToken = try await getValidAccessToken()
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
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
        try await addAuthHeaders(&request)
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
        try await addAuthHeaders(&request)
        
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
        try await addAuthHeaders(&request)
        
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
