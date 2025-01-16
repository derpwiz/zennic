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
}
