import Foundation

enum APIError: LocalizedError {
    case serverError(message: String)
    case invalidCredentials
    case unauthorized
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .serverError(let message):
            return message
        case .invalidCredentials:
            return "Invalid credentials"
        case .unauthorized:
            return "Unauthorized access"
        case .unknown:
            return "An unknown error occurred"
        }
    }
}
