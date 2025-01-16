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
    @State private var showingOAuthModal = false                         // Controls visibility of OAuth modal
    @State private var isConnectingWithOAuth = false                     // Loading state for OAuth connection
    @State private var showingOAuthError = false                         // Controls visibility of OAuth error alert
    @State private var oauthError: String = ""                           // Stores OAuth error message
    
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
                SecureField("Alpaca API Key", text: Binding(
                    get: { appViewModel.alpacaApiKey },
                    set: { newValue in
                        appViewModel.alpacaApiKey = newValue
                        appViewModel.saveSettings()
                    }
                ))
                SecureField("Alpaca API Secret", text: Binding(
                    get: { appViewModel.alpacaApiSecret },
                    set: { newValue in
                        appViewModel.alpacaApiSecret = newValue
                        appViewModel.saveSettings()
                    }
                ))
                
                Button(action: {
                    showingOAuthModal = true
                }) {
                    HStack {
                        Image(systemName: "link.badge.plus")
                        Text("Connect with OAuth")
                    }
                }
                .disabled(appViewModel.alpacaApiKey.isEmpty || appViewModel.alpacaApiSecret.isEmpty)
                
                if !appViewModel.alpacaApiKey.isEmpty && !appViewModel.alpacaApiSecret.isEmpty {
                    if appViewModel.isOAuthTokenValid {
                        Text("Connected with OAuth")
                            .foregroundColor(.green)
                            .font(.callout)
                    } else {
                        Text("Please connect with OAuth to verify your API keys")
                            .foregroundColor(.secondary)
                            .font(.callout)
                    }
                }
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
                Toggle("Paper Trading", isOn: $appViewModel.isPaperTrading)
                Toggle("Auto-Trading", isOn: $appViewModel.isAutoTradingEnabled)
                
                if appViewModel.isAutoTradingEnabled {
                    Toggle("Risk Management", isOn: $appViewModel.isRiskManagementEnabled)
                    Toggle("Position Sizing", isOn: $appViewModel.isPositionSizingEnabled)
                }
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
        .sheet(isPresented: $showingOAuthModal) {
            NavigationView {
                VStack {
                    if isConnectingWithOAuth {
                        ProgressView("Connecting to Alpaca...")
                    } else {
                        Text("Connect your Alpaca account")
                            .font(.headline)
                            .padding()
                        
                        Text("This will verify your API keys and enable trading.")
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding()
                        
                        Button(action: {
                            connectWithOAuth()
                        }) {
                            HStack {
                                Image(systemName: "link")
                                Text("Connect with Alpaca")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .padding()
                    }
                }
                .padding()
                .navigationTitle("Connect Account")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            showingOAuthModal = false
                        }
                    }
                }
            }
        }
        .alert("Authentication Error", isPresented: $showingAuthenticationError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(authenticationError)
        }
        .alert("OAuth Error", isPresented: $showingOAuthError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(oauthError)
        }
    }
    
    private func connectWithOAuth() {
        isConnectingWithOAuth = true
        
        Task {
            do {
                let service = AlpacaService.shared
                let response = try await service.authenticateWithAlpaca()
                
                // Store the OAuth response
                await MainActor.run {
                    appViewModel.alpacaOAuthToken = response.accessToken
                    appViewModel.alpacaOAuthTokenExpiration = Date().addingTimeInterval(TimeInterval(response.expiresIn))
                    showingOAuthModal = false
                }
            } catch {
                await MainActor.run {
                    oauthError = error.localizedDescription
                    showingOAuthError = true
                }
            }
            
            await MainActor.run {
                isConnectingWithOAuth = false
            }
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
