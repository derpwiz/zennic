import SwiftUI
import Combine
import Foundation

@MainActor
final class AppViewModel: ObservableObject {
    @Published var selectedTab: NavigationItem = .dashboard
    @Published var isLoading = false
    @Published var currentAlert: AlertItem?
    @Published var holdings: [PortfolioHolding] = []
    @Published var isAuthenticated: Bool = false
    @Published var requireAuthentication = false
    @Published var alpacaApiKey: String = ""
    @Published var alpacaApiSecret: String = ""
    @Published var alpacaOAuthToken: String = ""
    @Published var alpacaOAuthTokenExpiration: Date?
    @Published var isPaperTrading: Bool = true
    @Published var isAutoTradingEnabled: Bool = false
    @Published var isRiskManagementEnabled: Bool = true
    @Published var isPositionSizingEnabled: Bool = true
    @Published var realTimeMarket: RealTimeMarketViewModel
    
    // Services
    private var marketDataService: MarketDataService
    private var portfolioService: PortfolioService
    private let userDefaults = UserDefaults.standard
    private var cancellables = Set<AnyCancellable>()
    
    init(alpacaApiKey: String = "", alpacaApiSecret: String = "") {
        self.marketDataService = MarketDataService(apiKey: alpacaApiKey, apiSecret: alpacaApiSecret)
        self.portfolioService = PortfolioService()
        
        // Initialize real-time market data with stored API credentials
        self.realTimeMarket = RealTimeMarketViewModel(
            apiKey: userDefaults.string(forKey: "alpacaApiKey") ?? "",
            apiSecret: userDefaults.string(forKey: "alpacaApiSecret") ?? ""
        )
        
        // Load saved settings
        self.requireAuthentication = userDefaults.bool(forKey: "requireAuthentication")
        self.alpacaApiKey = userDefaults.string(forKey: "alpacaApiKey") ?? ""
        self.alpacaApiSecret = userDefaults.string(forKey: "alpacaApiSecret") ?? ""
        self.alpacaOAuthToken = userDefaults.string(forKey: "alpacaOAuthToken") ?? ""
        if let expirationTimeInterval = userDefaults.object(forKey: "alpacaOAuthTokenExpiration") as? TimeInterval {
            self.alpacaOAuthTokenExpiration = Date(timeIntervalSince1970: expirationTimeInterval)
        }
        self.isPaperTrading = userDefaults.bool(forKey: "isPaperTrading")
        self.isAutoTradingEnabled = userDefaults.bool(forKey: "isAutoTradingEnabled")
        self.isRiskManagementEnabled = userDefaults.bool(forKey: "isRiskManagementEnabled")
        self.isPositionSizingEnabled = userDefaults.bool(forKey: "isPositionSizingEnabled")
        
        // Subscribe to portfolio changes
        portfolioService.$holdings
            .receive(on: DispatchQueue.main)
            .sink { [weak self] holdings in
                self?.holdings = holdings
            }
            .store(in: &cancellables)
        
        // Connect to WebSocket when authenticated
        $isAuthenticated
            .sink { [weak self] authenticated in
                if authenticated {
                    self?.realTimeMarket.connect()
                } else {
                    self?.realTimeMarket.disconnect()
                }
            }
            .store(in: &cancellables)
    }
    
    func addHolding(_ holding: PortfolioHolding) {
        portfolioService.addHolding(holding)
        showAlert(title: "Success", message: "Added \(holding.symbol) to portfolio")
    }
    
    func removeHolding(_ holding: PortfolioHolding) {
        portfolioService.removeHolding(holding)
        showAlert(title: "Success", message: "Removed \(holding.symbol) from portfolio")
    }
    
    private func showAlert(title: String, message: String) {
        currentAlert = AlertItem(title: title, message: message)
    }
    
    // Save settings when they change
    func saveSettings() {
        userDefaults.set(requireAuthentication, forKey: "requireAuthentication")
        userDefaults.set(alpacaApiKey, forKey: "alpacaApiKey")
        userDefaults.set(alpacaApiSecret, forKey: "alpacaApiSecret")
        userDefaults.set(alpacaOAuthToken, forKey: "alpacaOAuthToken")
        if let expiration = alpacaOAuthTokenExpiration {
            userDefaults.set(expiration.timeIntervalSince1970, forKey: "alpacaOAuthTokenExpiration")
        }
        userDefaults.set(isPaperTrading, forKey: "isPaperTrading")
        userDefaults.set(isAutoTradingEnabled, forKey: "isAutoTradingEnabled")
        userDefaults.set(isRiskManagementEnabled, forKey: "isRiskManagementEnabled")
        userDefaults.set(isPositionSizingEnabled, forKey: "isPositionSizingEnabled")
    }
    
    // Check if OAuth token is valid
    var isOAuthTokenValid: Bool {
        guard let expiration = alpacaOAuthTokenExpiration else { return false }
        return !alpacaOAuthToken.isEmpty && Date() < expiration
    }
    
    // Clear all authentication data
    func clearAuthenticationData() {
        alpacaApiKey = ""
        alpacaApiSecret = ""
        alpacaOAuthToken = ""
        alpacaOAuthTokenExpiration = nil
        saveSettings()
    }
}
