import Foundation
import SwiftUI

public struct DataIntegration {
    // This empty struct serves to define the module
}

// Re-export AlpacaService to make it available when importing DataIntegration
public typealias AlpacaService = DataIntegration_AlpacaService

// Make sure AlpacaService is publicly accessible
public let AlpacaServiceType = DataIntegration_AlpacaService.self

// Import AlpacaServiceManager
import DataIntegration
