import SwiftUI
import LocalAuthentication

/// View for managing application settings and preferences
/// Provides controls for security, API keys, appearance, notifications, and other app configurations
struct SettingsView: View {
    @EnvironmentObject private var appViewModel: AppViewModel
    @AppStorage("isDarkMode") private var isDarkMode = false              // Persistent storage for dark mode preference
    @AppStorage("enableNotifications") private var enableNotifications = true  // Persistent storage for notifications preference
    @State private var showingAuthenticationError = false                 // Controls visibility of authentication error alert
    @State private var authenticationError: String = ""                   // Stores authentication error message
    
    /// Authenticates user using device biometrics (Touch ID/Face ID)
    /// - Parameter completion: Closure called with authentication result (success/failure)
    func authenticateWithBiometrics(completion: @escaping (Bool) -> Void) {
        let context = LAContext()
        var error: NSError?
        
        // Check if device supports biometric authentication
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Verify your identity to change authentication settings"
            
            // Attempt biometric authentication
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, error in
                DispatchQueue.main.async {
                    if success {
                        completion(true)
                    } else {
                        authenticationError = error?.localizedDescription ?? "Authentication failed"
                        showingAuthenticationError = true
                        completion(false)
                    }
                }
            }
        } else {
            authenticationError = error?.localizedDescription ?? "Biometric authentication not available"
            showingAuthenticationError = true
            completion(false)
        }
    }
    
    var body: some View {
        Form {
            // Security settings section
            Section("Security") {
                Toggle("Require Touch ID", isOn: Binding(
                    get: { appViewModel.requireAuthentication },
                    set: { newValue in
                        if appViewModel.requireAuthentication {
                            authenticateWithBiometrics { success in
                                if success {
                                    appViewModel.requireAuthentication = newValue
                                }
                            }
                        } else {
                            appViewModel.requireAuthentication = newValue
                        }
                    }
                ))
                
                if appViewModel.requireAuthentication {
                    Text("Touch ID will be required to access the app")
                        .foregroundColor(.secondary)
                        .font(.callout)
                }
            }
            
            // API configuration section
            Section("API Keys") {
                SecureField("Alpha Vantage API Key", text: $appViewModel.alphaVantageApiKey)
                SecureField("OpenAI API Key", text: $appViewModel.openAIApiKey)
            }
            
            // App appearance settings
            Section("Appearance") {
                Toggle("Dark Mode", isOn: $isDarkMode)
            }
            
            // Notification preferences
            Section("Notifications") {
                Toggle("Enable Notifications", isOn: $enableNotifications)
                
                if enableNotifications {
                    Toggle("Price Alerts", isOn: .constant(true))
                    Toggle("Trading Signals", isOn: .constant(true))
                    Toggle("Portfolio Updates", isOn: .constant(true))
                }
            }
            
            // Trading-related settings
            Section("Trading") {
                Toggle("Confirm Orders", isOn: .constant(true))
                Toggle("Show Order Preview", isOn: .constant(true))
            }
            
            // Data management options
            Section("Data") {
                Button("Clear Cache") {
                    // TODO: Implement cache clearing
                }
                
                Button("Export Portfolio Data") {
                    // TODO: Implement data export
                }
                
                Button("Reset All Settings") {
                    // TODO: Implement settings reset
                }
                .foregroundColor(.red)
            }
            
            // App information and legal links
            Section("About") {
                LabeledContent("Version", value: "1.0.0")
                LabeledContent("Build", value: "100")
                
                Link("Privacy Policy",
                     destination: URL(string: "https://www.aihedgefund.com/privacy")!)
                
                Link("Terms of Service",
                     destination: URL(string: "https://www.aihedgefund.com/terms")!)
            }
        }
        .formStyle(.grouped)
        .alert("Authentication Error", isPresented: $showingAuthenticationError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(authenticationError)
        }
    }
}

/// Preview provider for SwiftUI canvas
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(AppViewModel())
    }
}
