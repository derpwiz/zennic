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
    @Published var alpacaSecretKey: String = ""
    @Published var alpacaOAuthToken: String = ""
    @Published var alpacaOAuthTokenExpiration: Date?
    @Published var isPaperTrading: Bool = true
    @Published var isAutoTradingEnabled: Bool = false
    @Published var isRiskManagementEnabled: Bool = true
    @Published var isPositionSizingEnabled: Bool = true
    
    // Services
    private var marketDataService: MarketDataService
    private var portfolioService: PortfolioService
    private let userDefaults = UserDefaults.standard
    private let keychain = KeychainService.shared
    private var cancellables = Set<AnyCancellable>()
    private var webSocketService: WebSocketService
    private var portfolioTask: Task<Void, Never>?
    
    // Real-time market components
    private(set) var realTimeMarket: RealTimeMarket
    private(set) var realTimeMarketViewModel: RealTimeMarketViewModel
    
    deinit {
        cancellables.removeAll()
        portfolioTask?.cancel()
        
        // Ensure cleanup happens on main actor without capturing self
        let service = webSocketService
        let market = realTimeMarket
        let viewModel = realTimeMarketViewModel
        Task { @MainActor in
            service.removeObserver(market)
            service.removeObserver(viewModel)
        }
    }
    
    init(alpacaApiKey: String = "", alpacaSecretKey: String = "") {
        // Initialize services
        self.marketDataService = MarketDataService.shared
        self.portfolioService = PortfolioService()
        self.webSocketService = WebSocketService.shared
        
        // Initialize real-time market components
        self.realTimeMarket = RealTimeMarket()
        self.realTimeMarketViewModel = RealTimeMarketViewModel()
        
        // Load stored credentials
        let storedApiKey = (try? keychain.retrieveString(forKey: "alpacaApiKey")) ?? ""
        let storedSecretKey = (try? keychain.retrieveString(forKey: "alpacaSecretKey")) ?? ""
        
        // Load saved settings
        self.requireAuthentication = userDefaults.bool(forKey: "requireAuthentication")
        self.alpacaApiKey = storedApiKey
        self.alpacaSecretKey = storedSecretKey
        self.alpacaOAuthToken = (try? keychain.retrieveString(forKey: "alpacaOAuthToken")) ?? ""
        if let expirationTimeInterval = userDefaults.object(forKey: "alpacaOAuthTokenExpiration") as? TimeInterval {
            self.alpacaOAuthTokenExpiration = Date(timeIntervalSince1970: expirationTimeInterval)
        }
        self.isPaperTrading = userDefaults.bool(forKey: "isPaperTrading")
        self.isAutoTradingEnabled = userDefaults.bool(forKey: "isAutoTradingEnabled")
        self.isRiskManagementEnabled = userDefaults.bool(forKey: "isRiskManagementEnabled")
        self.isPositionSizingEnabled = userDefaults.bool(forKey: "isPositionSizingEnabled")
        
        // Register WebSocket observers
        webSocketService.addObserver(realTimeMarket)
        webSocketService.addObserver(realTimeMarketViewModel)
        
        // Set up observers
        setupObservers()
        
        // Subscribe to portfolio changes
        setupPortfolioSubscription()
        
        // Connect to WebSocket when authenticated
        $isAuthenticated
            .receive(on: DispatchQueue.main)
            .sink { [webSocketService] authenticated in
                if authenticated {
                    webSocketService.connect()
                } else {
                    webSocketService.disconnect()
                }
            }
            .store(in: &cancellables)
    }
    
    private func setupPortfolioSubscription() {
        portfolioTask?.cancel()
        let service = portfolioService
        portfolioTask = Task { [weak self] in
            for await newHoldings in service.$holdings.values {
                guard let self = self else { break }
                self.holdings = newHoldings
            }
        }
    }
    
    private func setupObservers() {
        NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)
            .sink { [weak self] _ in
                self?.loadSettings()
            }
            .store(in: &cancellables)
    }
    
    private func loadSettings() {
        requireAuthentication = userDefaults.bool(forKey: "requireAuthentication")
        alpacaApiKey = (try? keychain.retrieveString(forKey: "alpacaApiKey")) ?? ""
        alpacaSecretKey = (try? keychain.retrieveString(forKey: "alpacaSecretKey")) ?? ""
        alpacaOAuthToken = (try? keychain.retrieveString(forKey: "alpacaOAuthToken")) ?? ""
        if let expirationTimeInterval = userDefaults.object(forKey: "alpacaOAuthTokenExpiration") as? TimeInterval {
            alpacaOAuthTokenExpiration = Date(timeIntervalSince1970: expirationTimeInterval)
        }
        isPaperTrading = userDefaults.bool(forKey: "isPaperTrading")
        isAutoTradingEnabled = userDefaults.bool(forKey: "isAutoTradingEnabled")
        isRiskManagementEnabled = userDefaults.bool(forKey: "isRiskManagementEnabled")
        isPositionSizingEnabled = userDefaults.bool(forKey: "isPositionSizingEnabled")
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
    
    func saveSettings() {
        userDefaults.set(requireAuthentication, forKey: "requireAuthentication")
        // Store sensitive data in keychain
        try? keychain.storeString(alpacaApiKey, forKey: "alpacaApiKey")
        try? keychain.storeString(alpacaSecretKey, forKey: "alpacaSecretKey")
        try? keychain.storeString(alpacaOAuthToken, forKey: "alpacaOAuthToken")
        if let expirationDate = alpacaOAuthTokenExpiration {
            userDefaults.set(expirationDate.timeIntervalSince1970, forKey: "alpacaOAuthTokenExpiration")
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
        alpacaSecretKey = ""
        alpacaOAuthToken = ""
        alpacaOAuthTokenExpiration = nil
        // Remove sensitive data from keychain
        try? keychain.delete(key: "alpacaApiKey")
        try? keychain.delete(key: "alpacaSecretKey")
        try? keychain.delete(key: "alpacaOAuthToken")
        saveSettings()
    }
    
    func updateAPICredentials(apiKey: String, secretKey: String) {
        Task { @MainActor in
            do {
                // Disconnect existing connections
                webSocketService.disconnect()
                
                // Update stored credentials securely
                try keychain.storeString(apiKey, forKey: "alpacaApiKey")
                try keychain.storeString(secretKey, forKey: "alpacaSecretKey")
                
                // Update instance variables
                self.alpacaApiKey = apiKey
                self.alpacaSecretKey = secretKey
                
                // Clean up existing observers
                webSocketService.removeObserver(realTimeMarket)
                webSocketService.removeObserver(realTimeMarketViewModel)
                
                // Update shared services with new credentials
                WebSocketService.updateShared(apiKey: apiKey, apiSecret: secretKey)
                MarketDataService.updateShared(apiKey: apiKey, apiSecret: secretKey)
                
                // Update service instances
                self.marketDataService = MarketDataService.shared
                self.webSocketService = WebSocketService.shared
                
                // Re-register observers with new WebSocket service
                webSocketService.addObserver(realTimeMarket)
                webSocketService.addObserver(realTimeMarketViewModel)
                
                // Reconnect if authenticated
                if isAuthenticated {
                    webSocketService.connect()
                }
                
                // Notify user of successful update
                showAlert(title: "Success", message: "API credentials updated successfully")
            } catch {
                showAlert(title: "Error", message: "Failed to store API credentials securely")
            }
        }
    }
    
    func togglePaperTrading() {
        isPaperTrading.toggle()
        saveSettings()
    }
    
    func toggleAutoTrading() {
        isAutoTradingEnabled.toggle()
        saveSettings()
    }
    
    func toggleRiskManagement() {
        isRiskManagementEnabled.toggle()
        saveSettings()
    }
    
    func togglePositionSizing() {
        isPositionSizingEnabled.toggle()
        saveSettings()
    }
}
