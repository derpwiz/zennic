import SwiftUI
import LocalAuthentication

struct AuthenticationView: View {
    @EnvironmentObject private var appViewModel: AppViewModel
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "lock.shield")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("Authentication Required")
                .font(.title)
                .fontWeight(.bold)
            
            Button("Use Touch ID") {
                authenticateWithBiometrics()
            }
            .buttonStyle(.borderedProminent)
            
            if showError {
                Text(errorMessage)
                    .foregroundColor(.red)
            }
        }
        .padding()
        .onAppear {
            authenticateWithBiometrics()
        }
    }
    
    private func authenticateWithBiometrics() {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
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

struct AuthenticationView_Previews: PreviewProvider {
    static var previews: some View {
        AuthenticationView()
            .environmentObject(AppViewModel())
    }
}
