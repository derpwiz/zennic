import Foundation
import SwiftUI
import DataIntegration
import LocalAuthentication
import Shared

// Export Core module's public interface
public enum Git {
    public static let shared = GitService.shared
}

// Define AppState at module level
public class AppState: ObservableObject {
    public static let shared = AppState()
    
    @Published public var selectedFeature: String?
    @Published public var isDarkMode: Bool = false
    @Published public var isAppLocked: Bool = false
    @Published public var currentCode: String = ""
    @Published public var currentLanguage: String = ""
    public var alpacaService: AlpacaService?
    
    public init() {
        // Initialize with a nil alpacaService
        self.alpacaService = nil
        
        // Load saved settings
        self.isDarkMode = UserDefaults.standard.bool(forKey: "isDarkMode")
        self.isAppLocked = UserDefaults.standard.bool(forKey: "isAppLocked")
        self.currentLanguage = UserDefaults.standard.string(forKey: "currentLanguage") ?? CodeLanguage.python.rawValue
        self.currentCode = UserDefaults.standard.string(forKey: "currentCode") ?? ""
    }
    
    public func toggleDarkMode() {
        isDarkMode.toggle()
        UserDefaults.standard.set(isDarkMode, forKey: "isDarkMode")
    }
    
    public func toggleAppLock() {
        isAppLocked.toggle()
        UserDefaults.standard.set(isAppLocked, forKey: "isAppLocked")
    }
    
    public func getCodeHistory(language: CodeLanguage) -> [String] {
        let key = "codeHistory_\(language.rawValue)"
        return UserDefaults.standard.stringArray(forKey: key) ?? []
    }
    
    public func saveToHistory(code: String, language: CodeLanguage) {
        let key = "codeHistory_\(language.rawValue)"
        var history = getCodeHistory(language: language)
        history.append(code)
        if history.count > 10 { // Keep only last 10 entries
            history.removeFirst()
        }
        UserDefaults.standard.set(history, forKey: key)
    }
    
    public func authenticateWithTouchID(completion: @escaping (Bool) -> Void) {
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

// Export shared AppState instance
public let appState = AppState.shared
