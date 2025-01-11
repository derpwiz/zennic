import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var appViewModel: AppViewModel
    @State private var selectedTab: NavigationItem = .dashboard
    
    var body: some View {
        Group {
            if appViewModel.requireAuthentication && !appViewModel.isAuthenticated {
                AuthenticationView()
                    .environmentObject(appViewModel)
            } else {
                NavigationSplitView {
                    Sidebar(selection: $selectedTab)
                } detail: {
                    TabContentView(selectedTab: selectedTab)
                }
            }
        }
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

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(AppViewModel())
    }
}
