import SwiftUI
import Foundation

public class AlpacaServiceManager: ObservableObject {
    @Published public var alpacaService: AlpacaService?
    
    public init() {}
    
    public func setAlpacaService(accessToken: String) {
        alpacaService = AlpacaService(accessToken: accessToken)
    }
}
