import SwiftUI
import Foundation
import DataIntegration

public class AlpacaServiceManager: ObservableObject {
    @Published public var alpacaService: AlpacaService?
    
    public init() {}
    
    public func setAlpacaService(accessToken: String) {
        alpacaService = AlpacaService(accessToken: accessToken)
    }
}
