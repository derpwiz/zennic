import Foundation

// Namespace for our app's models to avoid conflicts with backend models
enum AppModels {
    // Frontend representation of the backend User model
    struct User: Codable, Identifiable {
        let id: UUID?
        let email: String
        let username: String
        let fullName: String?
        let isActive: Bool
        
        enum CodingKeys: String, CodingKey {
            case id
            case email
            case username
            case fullName = "full_name"
            case isActive = "is_active"
        }
    }
    
    // Frontend representation of the backend AlpacaKeys model
    public struct AlpacaKeys: Codable {
        public let apiKey: String
        public let secretKey: String
        public let isPaper: Bool
        
        public init(apiKey: String, secretKey: String, isPaper: Bool) {
            self.apiKey = apiKey
            self.secretKey = secretKey
            self.isPaper = isPaper
        }
        
        enum CodingKeys: String, CodingKey {
            case apiKey = "api_key"
            case secretKey = "secret_key"
            case isPaper = "is_paper"
        }
    }
    
    // Frontend representation of the backend AlpacaKeysCreate model
    public struct AlpacaKeysCreate: Codable {
        public let apiKey: String
        public let secretKey: String
        public let isPaper: Bool
        
        public init(apiKey: String, secretKey: String, isPaper: Bool) {
            self.apiKey = apiKey
            self.secretKey = secretKey
            self.isPaper = isPaper
        }
        
        enum CodingKeys: String, CodingKey {
            case apiKey = "api_key"
            case secretKey = "secret_key"
            case isPaper = "is_paper"
        }
    }
    
    // Response when creating or retrieving AlpacaKeys
    public struct AlpacaKeysResponse: Codable {
        public let apiKey: String
        public let isPaper: Bool
        
        enum CodingKeys: String, CodingKey {
            case apiKey = "api_key"
            case isPaper = "is_paper"
        }
    }
    
    // Request model for login
    struct LoginRequest: Codable {
        let email: String
        let password: String
    }
    
    // Response model for login
    struct LoginResponse: Codable {
        let token: String
        let user: User
        
        enum CodingKeys: String, CodingKey {
            case token
            case user
        }
    }
    
    // Request model for registration
    struct RegisterRequest: Codable {
        let email: String
        let username: String
        let password: String
        let fullName: String?
        
        enum CodingKeys: String, CodingKey {
            case email
            case username
            case password
            case fullName = "full_name"
        }
    }
    
    // Generic error response from the server
    struct ErrorResponse: Codable {
        let error: Bool
        let reason: String
    }
    
    // Request model for OAuth
    public struct AlpacaOAuthRequest: Codable {
        let clientId: String
        let redirectUri: String
        let responseType: String
        let scope: String
        
        enum CodingKeys: String, CodingKey {
            case clientId = "client_id"
            case redirectUri = "redirect_uri"
            case responseType = "response_type"
            case scope
        }
    }
    
    // Response model for OAuth
    public struct AlpacaOAuthResponse: Codable {
        let accessToken: String
        let tokenType: String
        let expiresIn: Int
        let scope: String
        
        enum CodingKeys: String, CodingKey {
            case accessToken = "access_token"
            case tokenType = "token_type"
            case expiresIn = "expires_in"
            case scope
        }
    }
    
    // Error model for OAuth
    public struct AlpacaOAuthError: Codable {
        let error: String
        let errorDescription: String
        
        enum CodingKeys: String, CodingKey {
            case error
            case errorDescription = "error_description"
        }
    }
}
