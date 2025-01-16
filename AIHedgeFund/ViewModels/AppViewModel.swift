import SwiftUI
import Combine

@MainActor
final class AppViewModel: ObservableObject {
    @Published var selectedTab: NavigationItem = .dashboard
    @Published var isLoading = false
    @Published var currentAlert: AlertItem?
    @Published var holdings: [PortfolioHolding] = []
    @Published var isAuthenticated: Bool = false
    
    // API Keys and Settings
    @AppStorage("alpacaApiKey") var alpacaApiKey: String = ""
    @AppStorage("alpacaApiSecret") var alpacaApiSecret: String = ""
    @AppStorage("requireAuthentication") var requireAuthentication: Bool = false
    
    // Services
    private var marketDataService: MarketDataService
    private var portfolioService: PortfolioService
    private var cancellables = Set<AnyCancellable>()
    
    init(alpacaApiKey: String = "", alpacaApiSecret: String = "") {
        self.marketDataService = MarketDataService(apiKey: alpacaApiKey, apiSecret: alpacaApiSecret)
        self.portfolioService = PortfolioService()
        
        // Subscribe to portfolio changes
        portfolioService.$holdings
            .receive(on: DispatchQueue.main)
            .sink { [weak self] holdings in
                self?.holdings = holdings
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
}
