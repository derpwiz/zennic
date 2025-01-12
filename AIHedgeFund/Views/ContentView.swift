import SwiftUI

/// Root view of the application
/// Manages authentication state and navigation structure
struct ContentView: View {
    @EnvironmentObject private var appViewModel: AppViewModel
    @State private var selectedTab: NavigationItem = .dashboard    // Currently selected navigation tab
    
    var body: some View {
        Group {
            // Show authentication view if required and not authenticated
            if appViewModel.requireAuthentication && !appViewModel.isAuthenticated {
                AuthenticationView()
                    .environmentObject(appViewModel)
            } else {
                // Main navigation structure using split view
                NavigationSplitView {
                    Sidebar(selection: $selectedTab)
                } detail: {
                    TabContentView(selectedTab: selectedTab)
                }
            }
        }
        // Global alert handling
        .alert(
            appViewModel.currentAlert?.title ?? "",
            isPresented: Binding(
                get: { appViewModel.currentAlert != nil },
                set: { if !$0 { appViewModel.currentAlert = nil } }
            ),
            actions: { Button("OK") { appViewModel.currentAlert = nil } },
            message: { Text(appViewModel.currentAlert?.message ?? "") }
        )
    }
}

/// Preview provider for SwiftUI canvas
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(AppViewModel())
    }
}
