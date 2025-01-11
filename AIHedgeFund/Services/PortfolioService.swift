import Foundation
import Combine

class PortfolioService {
    @Published private(set) var holdings: [PortfolioHolding] = []
    private let userDefaults = UserDefaults.standard
    private let holdingsKey = "portfolio.holdings"
    
    init() {
        loadHoldings()
    }
    
    func addHolding(_ holding: PortfolioHolding) {
        holdings.append(holding)
        saveHoldings()
    }
    
    func removeHolding(_ holding: PortfolioHolding) {
        holdings.removeAll { $0.id == holding.id }
        saveHoldings()
    }
    
    private func loadHoldings() {
        if let data = userDefaults.data(forKey: holdingsKey),
           let holdings = try? JSONDecoder().decode([PortfolioHolding].self, from: data) {
            self.holdings = holdings
        }
    }
    
    private func saveHoldings() {
        if let data = try? JSONEncoder().encode(holdings) {
            userDefaults.set(data, forKey: holdingsKey)
        }
    }
}
