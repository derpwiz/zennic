import Foundation

enum APIError: LocalizedError {
    case serverError(message: String)
    case invalidCredentials
    case unauthorized
    case invalidResponse
    case authenticationFailed
    case unknown
    case httpError(statusCode: Int)
    
    var errorDescription: String? {
        switch self {
        case .serverError(let message):
            return message
        case .invalidCredentials:
            return "Invalid credentials"
        case .unauthorized:
            return "Unauthorized access"
        case .invalidResponse:
            return "Invalid response from server"
        case .authenticationFailed:
            return "Authentication failed"
        case .unknown:
            return "An unknown error occurred"
        case .httpError(let statusCode):
            return "HTTP error with status code: \(statusCode)"
        }
    }
}
