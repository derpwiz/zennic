import Foundation
import SwiftUI

public class AppState: ObservableObject {
    public static let shared = AppState()
    
    @Published public var isDarkMode: Bool = false
    
    private init() {}
}
