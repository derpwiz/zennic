import SwiftUI
import Core

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        Form {
            Section(header: Text("Appearance")) {
                Toggle("Dark Mode", isOn: $appState.isDarkMode)
                    .onChange(of: appState.isDarkMode) { _ in
                        appState.toggleDarkMode()
                    }
            }
            
            Section(header: Text("Security")) {
                Toggle("Lock App with Touch ID", isOn: $appState.isAppLocked)
                    .onChange(of: appState.isAppLocked) { _ in
                        appState.toggleAppLock()
                    }
            }
        }
        .formStyle(GroupedFormStyle())
        .padding()
        .frame(idealWidth: 350, maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle("Settings")
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(AppState())
    }
}
