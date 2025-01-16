import Foundation
import Combine

@MainActor
class PortfolioService: ObservableObject {
    @Published private(set) var holdings: [PortfolioHolding] = []
    private let userDefaults = UserDefaults.standard
    private let holdingsKey = "portfolio.holdings"
    
    init() {
        loadHoldings()
    }
    
    func fetchHoldings() async throws -> [PortfolioHolding] {
        // In a real app, this would fetch from a server
        // For now, we'll just return the local holdings
        return holdings
    }
    
    func addHolding(_ holding: PortfolioHolding) {
        holdings.append(holding)
        saveHoldings()
        objectWillChange.send()
    }
    
    func removeHolding(_ holding: PortfolioHolding) {
        holdings.removeAll { $0.id == holding.id }
        saveHoldings()
        objectWillChange.send()
    }
    
    private func loadHoldings() {
        if let data = userDefaults.data(forKey: holdingsKey),
           let holdings = try? JSONDecoder().decode([PortfolioHolding].self, from: data) {
            self.holdings = holdings
            objectWillChange.send()
        }
    }
    
    private func saveHoldings() {
        if let data = try? JSONEncoder().encode(holdings) {
            userDefaults.set(data, forKey: holdingsKey)
        }
    }
}
