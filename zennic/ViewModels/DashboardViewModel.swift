import SwiftUI
import Combine
import os

@MainActor
final class DashboardViewModel: ObservableObject {
    @Published var selectedSymbol: String?
    @Published var barData: [StockBarData] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    private let portfolioService: PortfolioService
    private let alpacaService: AlpacaService
    private var cancellables = Set<AnyCancellable>()
    private let logger = Logger(subsystem: "com.zennic.app", category: "DashboardViewModel")
    
    var holdings: [PortfolioHolding] {
        portfolioService.holdings
    }
    
    init() {
        self.portfolioService = PortfolioService()
        self.alpacaService = .shared
        logger.info("DashboardViewModel initialized")
        
        Task {
            await loadData()
        }
        
        // Subscribe to holdings updates to trigger UI refresh when holdings change
        portfolioService.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
    
    func selectSymbol(_ symbol: String) {
        logger.info("Symbol selected: \(symbol)")
        selectedSymbol = symbol
        Task {
            await loadSelectedSymbolData(symbol: symbol)
        }
    }
    
    private func loadSelectedSymbolData(symbol: String) async {
        logger.info("Loading data for symbol: \(symbol)")
        isLoading = true
        error = nil
        
        do {
            let bars = try await alpacaService.fetchBarData(symbol: symbol)
            await MainActor.run {
                self.barData = bars
                self.isLoading = false
            }
        } catch {
            logger.error("Error loading data: \(error.localizedDescription)")
            await MainActor.run {
                self.error = error
                self.isLoading = false
            }
        }
    }
    
    private func loadData() async {
        logger.info("Loading initial data")
        isLoading = true
        error = nil
        
        do {
            let holdings = try await portfolioService.fetchHoldings()
            if let firstSymbol = holdings.first?.symbol {
                await loadSelectedSymbolData(symbol: firstSymbol)
            }
            isLoading = false
        } catch {
            logger.error("Error loading data: \(error.localizedDescription)")
            self.error = error
            isLoading = false
        }
    }
}
