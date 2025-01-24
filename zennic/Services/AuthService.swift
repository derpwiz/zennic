import Foundation
import Combine
import os

@MainActor
final class AuthService {
    static let shared = AuthService()
    
    // MARK: - Properties
    
    private let baseURL = ProcessInfo.processInfo.environment["API_BASE_URL"] ?? "http://localhost:8080"
    private let alpacaOAuthURL = "https://app.alpaca.markets/oauth/authorize"
    private let alpacaTokenURL = "https://api.alpaca.markets/oauth/token"
    private let keychain = KeychainService.shared
    private let session: URLSession
    private let clientId = ProcessInfo.processInfo.environment["ALPACA_CLIENT_ID"] ?? ""
    private let clientSecret = ProcessInfo.processInfo.environment["ALPACA_CLIENT_SECRET"] ?? ""
    private let redirectURI = "zennic://oauth/callback"
    
    // MARK: - Initialization
    
    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        self.session = URLSession(configuration: config)
    }
    
    // MARK: - App Authentication
    
    func register(email: String, username: String, password: String, fullName: String?) async throws -> AppModels.User {
        guard let url = URL(string: "\(baseURL)/users/register") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let registerData = AppModels.RegisterRequest(
            email: email,
            username: username,
            password: password,
            fullName: fullName
        )
        
        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(registerData)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        guard httpResponse.statusCode == 200 else {
            if let errorData = try? JSONDecoder().decode(AppModels.ErrorResponse.self, from: data) {
                throw APIError.serverError(message: errorData.reason)
            }
            throw URLError(.badServerResponse)
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(AppModels.User.self, from: data)
    }
    
    func login(email: String, password: String) async throws -> AppModels.LoginResponse {
        guard let url = URL(string: "\(baseURL)/users/login") else {
            throw URLError(.badURL)
        }
        
        // Create basic auth header
        let loginString = "\(email):\(password)"
        guard let loginData = loginString.data(using: .utf8) else {
            throw URLError(.badURL)
        }
        let base64LoginString = loginData.base64EncodedString()
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Basic \(base64LoginString)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        guard httpResponse.statusCode == 200 else {
            if httpResponse.statusCode == 401 {
                throw APIError.unauthorized
            }
            if let errorData = try? JSONDecoder().decode(AppModels.ErrorResponse.self, from: data) {
                throw APIError.serverError(message: errorData.reason)
            }
            throw URLError(.badServerResponse)
        }
        
        let decoder = JSONDecoder()
        let loginResponse = try decoder.decode(AppModels.LoginResponse.self, from: data)
        
        // Store the token securely
        try await Task.detached(operation: {
            try KeychainService.shared.storeString(loginResponse.token, forKey: "authToken")
        }).value
        
        return loginResponse
    }
    
    func getCurrentUser() async throws -> AppModels.User {
        let token: String
        do {
            token = try await Task.detached(operation: {
                try KeychainService.shared.retrieveString(forKey: "authToken")
            }).value
        } catch {
            throw APIError.unauthorized
        }
        
        guard let url = URL(string: "\(baseURL)/users/me") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        guard httpResponse.statusCode == 200 else {
            if httpResponse.statusCode == 401 {
                try? await Task.detached(operation: {
                    try KeychainService.shared.delete(key: "authToken")
                }).value
                throw APIError.unauthorized
            }
            if let errorData = try? JSONDecoder().decode(AppModels.ErrorResponse.self, from: data) {
                throw APIError.serverError(message: errorData.reason)
            }
            throw URLError(.badServerResponse)
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(AppModels.User.self, from: data)
    }
    
    func logout() async {
        // Clear app token
        try? await Task.detached(operation: {
            try KeychainService.shared.delete(key: "authToken")
        }).value
        
        // Clear Alpaca OAuth tokens
        await clearOAuthTokens()
    }
    
    // MARK: - Alpaca OAuth
    
    /// Authenticates with Alpaca using OAuth
    func authenticateWithOAuth() async throws -> OAuthToken {
        guard !clientId.isEmpty && !clientSecret.isEmpty else {
            throw APIError.invalidCredentials
        }
        
        // In a real app, you would initiate the OAuth flow here
        // For now, we'll check if we have a valid token
        if let token = try? await getValidOAuthToken() {
            return token
        }
        
        throw APIError.authenticationFailed
    }
    
    /// Validates the current OAuth token
    func validateOAuthToken() async -> Bool {
        do {
            _ = try await getValidOAuthToken()
            return true
        } catch {
            return false
        }
    }
    
    /// Clears all OAuth tokens
    func clearOAuthTokens() async {
        try? await Task.detached(operation: {
            try KeychainService.shared.delete(key: "alpacaAccessToken")
            try KeychainService.shared.delete(key: "alpacaRefreshToken")
            UserDefaults.standard.removeObject(forKey: "alpacaTokenExpiration")
        }).value
    }
    
    // MARK: - Private Methods
    
    private func getValidOAuthToken() async throws -> OAuthToken {
        // Check if we have a valid access token
        if let expirationDate = UserDefaults.standard.object(forKey: "alpacaTokenExpiration") as? Date,
           let accessToken = try? await Task.detached(operation: { try KeychainService.shared.retrieveString(forKey: "alpacaAccessToken") }).value,
           expirationDate > Date() {
            return OAuthToken(accessToken: accessToken, expirationDate: expirationDate)
        }
        
        // Try to refresh the token
        if let refreshToken = try? await Task.detached(operation: { try KeychainService.shared.retrieveString(forKey: "alpacaRefreshToken") }).value {
            return try await refreshOAuthToken(refreshToken)
        }
        
        throw APIError.unauthorized
    }
    
    private func refreshOAuthToken(_ refreshToken: String) async throws -> OAuthToken {
        guard let url = URL(string: alpacaTokenURL) else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let refreshData = [
            "grant_type": "refresh_token",
            "refresh_token": refreshToken,
            "client_id": clientId,
            "client_secret": clientSecret
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: refreshData)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw APIError.authenticationFailed
        }
        
        let tokenResponse = try JSONDecoder().decode(OAuthTokenResponse.self, from: data)
        let expirationDate = Date().addingTimeInterval(TimeInterval(tokenResponse.expiresIn))
        
        // Store the new tokens
        try await Task.detached(operation: {
            try KeychainService.shared.storeString(tokenResponse.accessToken, forKey: "alpacaAccessToken")
            try KeychainService.shared.storeString(tokenResponse.refreshToken, forKey: "alpacaRefreshToken")
            UserDefaults.standard.set(expirationDate, forKey: "alpacaTokenExpiration")
        }).value
        
        return OAuthToken(accessToken: tokenResponse.accessToken, expirationDate: expirationDate)
    }
}

// MARK: - Models

extension AuthService {
    struct OAuthToken {
        let accessToken: String
        let expirationDate: Date
    }
    
    private struct OAuthTokenResponse: Codable {
        let accessToken: String
        let refreshToken: String
        let expiresIn: Int
        
        enum CodingKeys: String, CodingKey {
            case accessToken = "access_token"
            case refreshToken = "refresh_token"
            case expiresIn = "expires_in"
        }
    }
}
