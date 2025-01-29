import SwiftUI

struct MainView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        NavigationSplitView {
            List(selection: $appState.selectedFeature) {
                NavigationLink(value: "CodeEditor") {
                    Label("Code Editor", systemImage: "doc.text")
                }
                NavigationLink(value: "DataIntegration") {
                    Label("Data Integration", systemImage: "arrow.triangle.2.circlepath")
                }
                NavigationLink(value: "Backtesting") {
                    Label("Backtesting", systemImage: "chart.xyaxis.line")
                }
                NavigationLink(value: "RealTimeMonitoring") {
                    Label("Real-Time Monitoring", systemImage: "chart.bar.xaxis")
                }
                NavigationLink(value: "Visualization") {
                    Label("Visualization", systemImage: "chart.pie")
                }
            }
            .listStyle(SidebarListStyle())
        } detail: {
            Group {
                switch appState.selectedFeature {
                case "CodeEditor":
                    CodeEditorView()
                case "DataIntegration":
                    DataIntegrationView()
                case "Backtesting":
                    BacktestingView()
                case "RealTimeMonitoring":
                    RealTimeMonitoringView()
                case "Visualization":
                    VisualizationView()
                default:
                    Text("Select a feature")
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
            .environmentObject(AppState())
    }
}
