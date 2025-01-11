import SwiftUI
import LocalAuthentication

struct SettingsView: View {
    @EnvironmentObject private var appViewModel: AppViewModel
    @AppStorage("isDarkMode") private var isDarkMode = false
    @AppStorage("enableNotifications") private var enableNotifications = true
    @State private var showingAuthenticationError = false
    @State private var authenticationError: String = ""
    
    func authenticateWithBiometrics(completion: @escaping (Bool) -> Void) {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Verify your identity to change authentication settings"
            
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
            
            Section("API Keys") {
                SecureField("Alpha Vantage API Key", text: $appViewModel.alphaVantageApiKey)
                SecureField("OpenAI API Key", text: $appViewModel.openAIApiKey)
            }
            
            Section("Appearance") {
                Toggle("Dark Mode", isOn: $isDarkMode)
            }
            
            Section("Notifications") {
                Toggle("Enable Notifications", isOn: $enableNotifications)
                
                if enableNotifications {
                    Toggle("Price Alerts", isOn: .constant(true))
                    Toggle("Trading Signals", isOn: .constant(true))
                    Toggle("Portfolio Updates", isOn: .constant(true))
                }
            }
            
            Section("Trading") {
                Toggle("Confirm Orders", isOn: .constant(true))
                Toggle("Show Order Preview", isOn: .constant(true))
            }
            
            Section("Data") {
                Button("Clear Cache") {
                    // Implement cache clearing
                }
                
                Button("Export Portfolio Data") {
                    // Implement data export
                }
                
                Button("Reset All Settings") {
                    // Implement settings reset
                }
                .foregroundColor(.red)
            }
            
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

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(AppViewModel())
    }
}
