import SwiftUI
import DataIntegration
import LocalAuthentication

class AppState: ObservableObject {
    @Published var selectedFeature: String?
    @Published var isDarkMode: Bool = false
    @Published var isAppLocked: Bool = false
    var alpacaService: AlpacaService?
    
    init() {
        // Initialize with a nil alpacaService
        self.alpacaService = nil
        
        // Load saved settings
        self.isDarkMode = UserDefaults.standard.bool(forKey: "isDarkMode")
        self.isAppLocked = UserDefaults.standard.bool(forKey: "isAppLocked")
    }
    
    func toggleDarkMode() {
        isDarkMode.toggle()
        UserDefaults.standard.set(isDarkMode, forKey: "isDarkMode")
    }
    
    func toggleAppLock() {
        isAppLocked.toggle()
        UserDefaults.standard.set(isAppLocked, forKey: "isAppLocked")
    }
    
    func authenticateWithTouchID(completion: @escaping (Bool) -> Void) {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Unlock Zennic") { success, authenticationError in
                DispatchQueue.main.async {
                    completion(success)
                }
            }
        } else {
            completion(false)
        }
    }
}
