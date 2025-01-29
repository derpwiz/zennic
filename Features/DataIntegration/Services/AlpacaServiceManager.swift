import SwiftUI

class AlpacaServiceManager: ObservableObject {
    @Published var alpacaService: AlpacaService?
    
    func setAlpacaService(accessToken: String) {
        alpacaService = AlpacaService(accessToken: accessToken)
    }
}
