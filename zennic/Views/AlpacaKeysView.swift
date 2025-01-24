import SwiftUI

struct AlpacaKeysView: View {
    @EnvironmentObject private var appViewModel: AppViewModel
    @StateObject private var viewModel = AlpacaKeysViewModel()
    @State private var showingAPIKeyForm = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Connect Your Alpaca Account")
                .font(.title)
                .multilineTextAlignment(.center)
            
            if viewModel.isAuthenticated {
                VStack(spacing: 16) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.system(size: 48))
                    
                    Text("Connected to Alpaca")
                        .font(.headline)
                    
                    Text("Your Alpaca account is successfully connected. You can now start trading.")
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Button(action: {
                        Task {
                            await viewModel.disconnect()
                        }
                    }) {
                        HStack {
                            Image(systemName: "link.badge.minus")
                                .imageScale(.large)
                            Text("Disconnect Account")
                                .fontWeight(.semibold)
                        }
                        .padding()
                        .frame(maxWidth: 300)
                        .background(Color.red.opacity(0.1))
                        .foregroundColor(.red)
                        .cornerRadius(10)
                    }
                }
            } else {
                VStack(spacing: 16) {
                    Text("Choose how you want to connect your Alpaca account:")
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    if viewModel.isLoading {
                        ProgressView()
                            .scaleEffect(1.5)
                            .padding()
                    } else {
                        // OAuth Button
                        Button(action: {
                            Task {
                                await viewModel.authenticateWithOAuth()
                            }
                        }) {
                            HStack {
                                Image(systemName: "link")
                                    .imageScale(.large)
                                Text("Connect with OAuth")
                                    .fontWeight(.semibold)
                            }
                            .padding()
                            .frame(maxWidth: 300)
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        
                        // API Key Button
                        Button(action: {
                            showingAPIKeyForm = true
                        }) {
                            HStack {
                                Image(systemName: "key")
                                    .imageScale(.large)
                                Text("Connect with API Keys")
                                    .fontWeight(.semibold)
                            }
                            .padding()
                            .frame(maxWidth: 300)
                            .background(Color.secondary.opacity(0.1))
                            .foregroundColor(.primary)
                            .cornerRadius(10)
                        }
                    }
                }
                .sheet(isPresented: $showingAPIKeyForm) {
                    NavigationView {
                        Form {
                            Section(header: Text("API Keys")) {
                                TextField("API Key", text: $viewModel.apiKey)
                                SecureField("Secret Key", text: $viewModel.secretKey)
                                Toggle("Paper Trading", isOn: $viewModel.isPaperTrading)
                            }
                            
                            Section {
                                Button(action: {
                                    Task {
                                        await viewModel.authenticateWithKeys()
                                        showingAPIKeyForm = false
                                    }
                                }) {
                                    Text("Connect")
                                }
                                .disabled(viewModel.apiKey.isEmpty || viewModel.secretKey.isEmpty)
                            }
                        }
                        .navigationTitle("Enter API Keys")
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Cancel") {
                                    showingAPIKeyForm = false
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .alert("Authentication Error", isPresented: .init(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.clearError() } }
        )) {
            Button("OK", role: .cancel) { }
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
        .onAppear {
            Task {
                await viewModel.checkAuthenticationStatus()
            }
        }
    }
}

#Preview {
    AlpacaKeysView()
        .environmentObject(AppViewModel())
}
