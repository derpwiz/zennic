import SwiftUI
import Shared
import CodeEditor
import DataIntegration
import Core
import Backtesting
import RealTimeMonitoring
import Visualization

struct MainView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        NavigationSplitView {
            List(selection: $appState.selectedFeature as Binding<String?>) {
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
                    DataIntegrationView(
                        clientID: "your_client_id",
                        clientSecret: "your_client_secret"
                    )
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
