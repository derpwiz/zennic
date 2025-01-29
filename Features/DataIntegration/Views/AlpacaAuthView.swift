import SwiftUI
import AppKit

struct AlpacaAuthView: View {
    @State private var clientID = ""
    @State private var clientSecret = ""
    @State private var isAuthenticating = false
    @State private var authenticationError: String?
    @State private var oauthService: AlpacaOAuthService?
    var onAuthentication: (Bool, String?) -> Void
    
    var body: some View {
        Form {
            Section(header: Text("Alpaca API Credentials")) {
                TextField("Client ID", text: $clientID)
                SecureField("Client Secret", text: $clientSecret)
            }
            
            Section {
                Button(action: authenticate) {
                    Text("Authenticate")
                }
                .disabled(clientID.isEmpty || clientSecret.isEmpty || isAuthenticating)
            }
            
            if isAuthenticating {
                ProgressView()
            }
            
            if let error = authenticationError {
                Text(error)
                    .foregroundColor(.red)
            }
        }
        .padding()
    }
    
    private func authenticate() {
        isAuthenticating = true
        authenticationError = nil
        
        oauthService = AlpacaOAuthService(clientID: clientID, clientSecret: clientSecret)
        
        guard let authURL = oauthService?.getAuthorizationURL() else {
            authenticationError = "Failed to create authorization URL"
            isAuthenticating = false
            return
        }
        
        NSWorkspace.shared.open(authURL)
        
        // In a real app, you would need to handle the redirect and extract the authorization code
        // For this example, we'll simulate receiving the code
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.handleAuthorizationCode("simulated_auth_code")
        }
    }
    
    private func handleAuthorizationCode(_ code: String) {
        Task {
            do {
                if let accessToken = try await oauthService?.exchangeCodeForToken(code: code) {
                    DispatchQueue.main.async {
                        self.isAuthenticating = false
                        self.onAuthentication(true, accessToken)
                        // In a real app, you would store the access token securely here
                    }
                } else {
                    throw NSError(domain: "AlpacaAuthView", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to obtain access token"])
                }
            } catch {
                DispatchQueue.main.async {
                    self.authenticationError = error.localizedDescription
                    self.isAuthenticating = false
                }
            }
        }
    }
}

struct AlpacaAuthView_Previews: PreviewProvider {
    static var previews: some View {
        AlpacaAuthView(onAuthentication: { success, token in
            print("Authentication \(success ? "succeeded" : "failed")")
            if let token = token {
                print("Token: \(token)")
            }
        })
    }
}
