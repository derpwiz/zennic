import Foundation
import SwiftUI
import Combine

@MainActor
final class AlpacaKeysViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published private(set) var isAuthenticated: Bool = false
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String?
    @Published var apiKey: String = "" {
        didSet {
            // Clear error when user starts typing
            if !apiKey.isEmpty {
                errorMessage = nil
            }
        }
    }
    @Published var secretKey: String = "" {
        didSet {
            // Clear error when user starts typing
            if !secretKey.isEmpty {
                errorMessage = nil
            }
        }
    }
    @Published var isPaperTrading: Bool = true
    
    // MARK: - Private Properties
    
    private let alpacaService: AlpacaService
    private let webSocketService: WebSocketService
    private let authService: AuthService
    private var cancellables = Set<AnyCancellable>()
    private let queue = DispatchQueue(label: "com.zennic.alpacakeys", qos: .userInitiated)
    
    // MARK: - Initialization
    
    init() {
        self.alpacaService = AlpacaService.shared
        self.webSocketService = WebSocketService.shared
        self.authService = AuthService.shared
        
        Task {
            await checkAuthenticationStatus()
        }
    }
    
    init(alpacaService: AlpacaService,
         webSocketService: WebSocketService,
         authService: AuthService) {
        self.alpacaService = alpacaService
        self.webSocketService = webSocketService
        self.authService = authService
        
        Task {
            await checkAuthenticationStatus()
        }
    }
    
    // MARK: - Public Methods
    
    func checkAuthenticationStatus() async {
        guard !isLoading else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Check for API key authentication
            if let keys = try await alpacaService.getAlpacaKeys() {
                await MainActor.run {
                    self.apiKey = keys.apiKey
                    self.isPaperTrading = keys.isPaperTrading
                    self.isAuthenticated = true
                    self.errorMessage = nil
                }
                return
            }
            
            // Check for OAuth authentication
            let isOAuthValid = await authService.validateOAuthToken()
            await MainActor.run {
                self.isAuthenticated = isOAuthValid
                self.errorMessage = isOAuthValid ? nil : "No valid authentication found"
            }
        } catch {
            await MainActor.run {
                self.isAuthenticated = false
                self.errorMessage = "Failed to check authentication status: \(error.localizedDescription)"
            }
        }
    }
    
    func authenticateWithKeys() async {
        guard !isLoading else { return }
        guard !apiKey.isEmpty && !secretKey.isEmpty else {
            errorMessage = "Please enter both API key and secret key"
            return
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let keys = AlpacaKeysCreate(
                apiKey: apiKey,
                apiSecret: secretKey,
                isPaperTrading: isPaperTrading
            )
            
            // Save keys to AlpacaService
            try await alpacaService.saveAlpacaKeys(keys)
            
            // Update WebSocketService with new credentials
            WebSocketService.updateShared(apiKey: apiKey, apiSecret: secretKey)
            
            await MainActor.run {
                self.isAuthenticated = true
                self.errorMessage = nil
            }
        } catch let error as APIError {
            await handleAPIError(error)
        } catch {
            await MainActor.run {
                self.isAuthenticated = false
                self.errorMessage = "Authentication failed: \(error.localizedDescription)"
            }
        }
    }
    
    func authenticateWithOAuth() async {
        guard !isLoading else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let token = try await authService.authenticateWithOAuth()
            
            // Update WebSocketService with OAuth token
            WebSocketService.updateShared(apiKey: token.accessToken, apiSecret: "")
            
            await MainActor.run {
                self.isAuthenticated = true
                self.errorMessage = nil
            }
        } catch let error as APIError {
            await handleAPIError(error)
        } catch {
            await MainActor.run {
                self.isAuthenticated = false
                self.errorMessage = "OAuth authentication failed: \(error.localizedDescription)"
            }
        }
    }
    
    func disconnect() async {
        guard !isLoading else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Remove OAuth tokens
            await authService.clearOAuthTokens()
            
            // Remove API keys
            try await alpacaService.deleteAlpacaKeys()
            
            // Update WebSocket service
            WebSocketService.updateShared(apiKey: "", apiSecret: "")
            
            await MainActor.run {
                self.isAuthenticated = false
                self.apiKey = ""
                self.secretKey = ""
                self.errorMessage = nil
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to disconnect: \(error.localizedDescription)"
            }
        }
    }
    
    // MARK: - Public Methods
    
    func clearError() {
        errorMessage = nil
    }
    
    // MARK: - Private Methods
    
    private func handleAPIError(_ error: APIError) async {
        await MainActor.run {
            self.isAuthenticated = false
            switch error {
            case .serverError(let message):
                self.errorMessage = "Server error: \(message)"
            case .unauthorized:
                self.errorMessage = "Please log in to connect your Alpaca account"
            case .invalidCredentials:
                self.errorMessage = "Invalid API keys. Please check and try again."
            case .invalidResponse:
                self.errorMessage = "Invalid response from Alpaca. Please try again."
            case .authenticationFailed:
                self.errorMessage = "Authentication failed. Please check your credentials."
            case .unknown:
                self.errorMessage = "An unexpected error occurred. Please try again."
            case .httpError(let statusCode):
                self.errorMessage = "HTTP error: \(statusCode)"
            }
        }
    }
}
