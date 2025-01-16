import SwiftUI
import LocalAuthentication

/// View that handles biometric authentication (Touch ID/Face ID)
/// Displays when the app requires user authentication to proceed
struct AuthenticationView: View {
    @EnvironmentObject private var appViewModel: AppViewModel
    @State private var showError: Bool = false     // Controls visibility of error message
    @State private var errorMessage: String = ""   // Stores authentication error message
    
    var body: some View {
        VStack(spacing: 20) {
            // Lock shield icon
            Image(systemName: "lock.shield")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("Authentication Required")
                .font(.title)
                .fontWeight(.bold)
            
            // Authentication button
            Button("Use Touch ID") {
                authenticateWithBiometrics()
            }
            .buttonStyle(.borderedProminent)
            
            // Error message display
            if showError {
                Text(errorMessage)
                    .foregroundColor(.red)
            }
        }
        .padding()
        .onAppear {
            // Attempt authentication when view appears
            authenticateWithBiometrics()
        }
    }
    
    /// Initiates biometric authentication using LocalAuthentication framework
    /// Updates app authentication state on success/failure
    private func authenticateWithBiometrics() {
        let context = LAContext()
        var error: NSError?
        
        // Check if device supports biometric authentication
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            // Attempt biometric authentication
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics,
                                 localizedReason: "Authenticate to access the app") { success, error in
                DispatchQueue.main.async {
                    if success {
                        appViewModel.isAuthenticated = true
                    } else {
                        showError = true
                        errorMessage = error?.localizedDescription ?? "Authentication failed"
                    }
                }
            }
        } else {
            showError = true
            errorMessage = error?.localizedDescription ?? "Biometric authentication not available"
        }
    }
}

/// Preview provider for SwiftUI canvas
struct AuthenticationView_Previews: PreviewProvider {
    static var previews: some View {
        AuthenticationView()
            .environmentObject(AppViewModel())
    }
}
