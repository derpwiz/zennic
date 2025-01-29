import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @State private var isUnlocked = false
    @State private var selectedFeature: String? = "CodeEditor"
    
    var body: some View {
        Group {
            if appState.isAppLocked && !isUnlocked {
                LockScreenView(isUnlocked: $isUnlocked)
            } else {
                NavigationView {
                    List(selection: $selectedFeature) {
                        NavigationLink(destination: CodeEditorView(), tag: "CodeEditor", selection: $selectedFeature) {
                            Label("Code Editor", systemImage: "chevron.left.forwardslash.chevron.right")
                        }
                        NavigationLink(destination: DataIntegrationView(), tag: "DataIntegration", selection: $selectedFeature) {
                            Label("Data Integration", systemImage: "arrow.triangle.2.circlepath")
                        }
                        NavigationLink(destination: BacktestingView(), tag: "Backtesting", selection: $selectedFeature) {
                            Label("Backtesting", systemImage: "chart.xyaxis.line")
                        }
                        NavigationLink(destination: RealTimeMonitoringView(), tag: "RealTimeMonitoring", selection: $selectedFeature) {
                            Label("Real-Time Monitoring", systemImage: "chart.bar.xaxis")
                        }
                        NavigationLink(destination: VisualizationView(), tag: "Visualization", selection: $selectedFeature) {
                            Label("Visualization", systemImage: "chart.pie")
                        }
                        NavigationLink(destination: SettingsView(), tag: "Settings", selection: $selectedFeature) {
                            Label("Settings", systemImage: "gear")
                        }
                    }
                    .listStyle(SidebarListStyle())
                    .frame(minWidth: 200, idealWidth: 250, maxWidth: 300)
                    
                    Text("Select a feature")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .navigationTitle("Zennic")
                .toolbar {
                    ToolbarItem(placement: .automatic) {
                        Button(action: toggleSidebar) {
                            Image(systemName: "sidebar.left")
                        }
                    }
                }
            }
        }
        .preferredColorScheme(appState.isDarkMode ? .dark : .light)
    }
    
    private func toggleSidebar() {
        NSApp.keyWindow?.firstResponder?.tryToPerform(#selector(NSSplitViewController.toggleSidebar(_:)), with: nil)
    }
}

struct LockScreenView: View {
    @EnvironmentObject var appState: AppState
    @Binding var isUnlocked: Bool
    
    var body: some View {
        VStack {
            Image(systemName: "lock.circle")
                .font(.system(size: 60))
                .padding()
            Text("Zennic is locked")
                .font(.title)
            Button("Unlock with Touch ID") {
                appState.authenticateWithTouchID { success in
                    isUnlocked = success
                }
            }
            .buttonStyle(.borderedProminent)
            .padding()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(AppState())
    }
}
