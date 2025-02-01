import SwiftUI
import Shared
import Core

public struct _MainView: View {
    @EnvironmentObject var appState: Core.AppState
    
    public init() {}
    
    public var body: some View {
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
                    Text("Code Editor")
                case "DataIntegration":
                    Text("Data Integration")
                case "Backtesting":
                    Text("Backtesting")
                case "RealTimeMonitoring":
                    Text("Real-Time Monitoring")
                case "Visualization":
                    Text("Visualization")
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
        _MainView()
            .environmentObject(Core.appState)
    }
}
