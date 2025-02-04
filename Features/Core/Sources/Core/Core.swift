import Foundation
import SwiftUI
import DataIntegration
import LocalAuthentication
import Shared

// Export Core module's public interface
public enum Core {
    public static let shared = GitService.shared
    
    // Re-export Git types from module scope
    public typealias GitServiceType = GitService
    public typealias GitErrorType = GitError
    public typealias GitCommitType = GitCommit
    public typealias GitStatusType = GitStatus
    
    // AppState
    public class AppState: ObservableObject {
        public static let shared = AppState()
        private let settingsManager = SettingsManager.shared
        
        @Published public var selectedFeature: String?
        @Published public var isDarkMode: Bool {
            didSet {
                settingsManager.isDarkMode = isDarkMode
            }
        }
        @Published public var isAppLocked: Bool = false
        @Published public var currentCode: String = ""
        @Published public var currentLanguage: String = ""
        public var alpacaService: AlpacaService?
        
        public init() {
            // Initialize with a nil alpacaService
            self.alpacaService = nil
            
            // Initialize from SettingsManager
            self.isDarkMode = settingsManager.isDarkMode
            
            // Load other saved settings
            self.isAppLocked = UserDefaults.standard.bool(forKey: "isAppLocked")
            self.currentLanguage = UserDefaults.standard.string(forKey: "currentLanguage") ?? CodeLanguage.python.rawValue
            self.currentCode = UserDefaults.standard.string(forKey: "currentCode") ?? ""
            
            // Listen for settings changes
            NotificationCenter.default.addObserver(self,
                                                 selector: #selector(handleSettingsChanged),
                                                 name: .settingsChanged,
                                                 object: nil)
        }
        
        @objc private func handleSettingsChanged() {
            // Update state when settings change
            self.isDarkMode = settingsManager.isDarkMode
        }
        
        public func toggleDarkMode() {
            isDarkMode.toggle()
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
    
    public static var appState: AppState {
        AppState.shared
    }
}
