import Foundation
import SwiftUI

@MainActor
final class AlpacaKeysViewModel: ObservableObject {
    @Published var apiKey: String = ""
    @Published var secretKey: String = ""
    @Published var isPaper: Bool = true
    @Published var hasKeys: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let alpacaService = AlpacaService.shared
    
    init() {
        Task {
            await checkExistingKeys()
        }
    }
    
    func checkExistingKeys() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let response = try await alpacaService.getAlpacaKeys()
            await MainActor.run {
                self.apiKey = response.apiKey
                // Don't set secretKey since it's not returned by the server
                self.isPaper = response.isPaper
                self.hasKeys = true
                self.errorMessage = nil
            }
        } catch let error as APIError {
            await MainActor.run {
                switch error {
                case .serverError(let message):
                    if message.contains("No Alpaca keys found") {
                        // This is expected for new users
                        self.hasKeys = false
                        self.errorMessage = nil
                    } else {
                        self.errorMessage = message
                    }
                case .unauthorized:
                    self.errorMessage = "Please log in to manage your Alpaca keys"
                case .invalidCredentials:
                    self.errorMessage = "Invalid credentials. Please log in again."
                case .unknown:
                    self.errorMessage = "An unexpected error occurred. Please try again."
                }
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    func saveKeys() async {
        isLoading = true
        defer { isLoading = false }
        
        let keys = AppModels.AlpacaKeysCreate(apiKey: apiKey, secretKey: secretKey, isPaper: isPaper)
        
        do {
            let response = try await alpacaService.saveAlpacaKeys(keys)
            await MainActor.run {
                self.apiKey = response.apiKey
                // Don't set secretKey since it's not returned by the server
                self.isPaper = response.isPaper
                self.hasKeys = true
                self.errorMessage = nil
            }
        } catch let error as APIError {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    func updateKeys() async {
        // Since we don't have a separate update endpoint,
        // we'll use the save endpoint which will overwrite existing keys
        await saveKeys()
    }
}
