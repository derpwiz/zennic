import Foundation
import SwiftUI

@MainActor
final class AlpacaKeysViewModel: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var apiKey: String = ""
    @Published var secretKey: String = ""
    @Published var isPaperTrading: Bool = true
    
    private let alpacaService = AlpacaService.shared
    
    init() {
        Task {
            await checkAuthenticationStatus()
        }
    }
    
    func checkAuthenticationStatus() async {
        isLoading = true
        defer { isLoading = false }
        
        // Check for API key authentication
        if let keys = try? await alpacaService.getAlpacaKeys() {
            await MainActor.run {
                self.apiKey = keys.apiKey
                self.isPaperTrading = keys.isPaper
                self.isAuthenticated = true
                self.errorMessage = nil
            }
            return
        }
        
        // Check for OAuth authentication
        if let expirationDate = UserDefaults.standard.object(forKey: "alpacaTokenExpiration") as? Date,
           let _ = UserDefaults.standard.string(forKey: "alpacaAccessToken"),
           expirationDate > Date() {
            isAuthenticated = true
            errorMessage = nil
        } else {
            isAuthenticated = false
        }
    }
    
    func authenticateWithKeys() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let keys = AppModels.AlpacaKeysCreate(
                apiKey: apiKey,
                secretKey: secretKey,
                isPaper: isPaperTrading
            )
            _ = try await alpacaService.saveAlpacaKeys(keys)
            await MainActor.run {
                self.isAuthenticated = true
                self.errorMessage = nil
            }
        } catch let error as APIError {
            await MainActor.run {
                self.isAuthenticated = false
                switch error {
                case .serverError(let message):
                    self.errorMessage = message
                case .unauthorized:
                    self.errorMessage = "Please log in to connect your Alpaca account"
                case .invalidCredentials:
                    self.errorMessage = "Invalid API keys. Please check and try again."
                case .invalidResponse:
                    self.errorMessage = "Invalid response from Alpaca. Please try again."
                case .authenticationFailed:
                    self.errorMessage = "Authentication failed. Please check your API keys."
                case .unknown:
                    self.errorMessage = "An unexpected error occurred. Please try again."
                }
            }
        } catch {
            await MainActor.run {
                self.isAuthenticated = false
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    func authenticateWithOAuth() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            _ = try await alpacaService.authenticateWithAlpaca()
            await MainActor.run {
                self.isAuthenticated = true
                self.errorMessage = nil
            }
        } catch let error as APIError {
            await MainActor.run {
                self.isAuthenticated = false
                switch error {
                case .serverError(let message):
                    self.errorMessage = message
                case .unauthorized:
                    self.errorMessage = "Please log in to connect your Alpaca account"
                case .invalidCredentials:
                    self.errorMessage = "Invalid credentials. Please try again."
                case .invalidResponse:
                    self.errorMessage = "Invalid response from Alpaca. Please try again."
                case .authenticationFailed:
                    self.errorMessage = "Authentication failed. Please try again."
                case .unknown:
                    self.errorMessage = "An unexpected error occurred. Please try again."
                }
            }
        } catch {
            await MainActor.run {
                self.isAuthenticated = false
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    func disconnect() async {
        isLoading = true
        defer { isLoading = false }
        
        // Remove OAuth tokens
        UserDefaults.standard.removeObject(forKey: "alpacaAccessToken")
        UserDefaults.standard.removeObject(forKey: "alpacaTokenExpiration")
        
        // Remove API keys
        do {
            try await alpacaService.deleteAlpacaKeys()
        } catch {
            self.errorMessage = "Failed to remove API keys: \(error.localizedDescription)"
        }
        
        isAuthenticated = false
        apiKey = ""
        secretKey = ""
    }
}
