import Foundation

@MainActor
final class AuthService {
    static let shared = AuthService()
    private let baseURL = "http://localhost:8080"
    private let userDefaults = UserDefaults.standard
    private let session: URLSession
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        self.session = URLSession(configuration: config)
    }
    
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
        
        // Store the token
        userDefaults.set(loginResponse.token, forKey: "authToken")
        userDefaults.synchronize()
        
        return loginResponse
    }
    
    func getCurrentUser() async throws -> AppModels.User {
        guard let token = userDefaults.string(forKey: "authToken") else {
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
                userDefaults.removeObject(forKey: "authToken")
                userDefaults.synchronize()
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
    
    func logout() {
        userDefaults.removeObject(forKey: "authToken")
        userDefaults.synchronize()
    }
}
