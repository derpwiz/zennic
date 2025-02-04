import SwiftUI
import Shared
import Core

public struct _MainView: View {
    @EnvironmentObject var appState: Core.AppState
    @State private var columnVisibility = NavigationSplitViewVisibility.automatic
    @State private var isShowingSettings = false
    
    public init() {}
    
    public var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            List(selection: $appState.selectedFeature as Binding<String?>) {
                Section {
                    NavigationLink(value: "CodeEditor") {
                        Label {
                            Text("Code Editor")
                                .font(.body)
                                .foregroundStyle(.primary)
                        } icon: {
                            Image(systemName: "doc.text")
                                .symbolRenderingMode(.hierarchical)
                                .foregroundStyle(.blue)
                                .fontWeight(.medium)
                        }
                    }
                    .buttonStyle(.plain)
                    .padding(.vertical, 2)
                    
                    NavigationLink(value: "DataIntegration") {
                        Label {
                            Text("Data Integration")
                                .font(.body)
                                .foregroundStyle(.primary)
                        } icon: {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .symbolRenderingMode(.hierarchical)
                                .foregroundStyle(.green)
                                .fontWeight(.medium)
                        }
                    }
                    .buttonStyle(.plain)
                    .padding(.vertical, 2)
                } header: {
                    Text("Development")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .fontWeight(.semibold)
                }
                
                Section {
                    NavigationLink(value: "Backtesting") {
                        Label {
                            Text("Backtesting")
                                .font(.body)
                                .foregroundStyle(.primary)
                        } icon: {
                            Image(systemName: "chart.xyaxis.line")
                                .symbolRenderingMode(.hierarchical)
                                .foregroundStyle(.purple)
                                .fontWeight(.medium)
                        }
                    }
                    .buttonStyle(.plain)
                    .padding(.vertical, 2)
                    
                    NavigationLink(value: "RealTimeMonitoring") {
                        Label {
                            Text("Real-Time Monitoring")
                                .font(.body)
                                .foregroundStyle(.primary)
                        } icon: {
                            Image(systemName: "chart.bar.xaxis")
                                .symbolRenderingMode(.hierarchical)
                                .foregroundStyle(.orange)
                                .fontWeight(.medium)
                        }
                    }
                    .buttonStyle(.plain)
                    .padding(.vertical, 2)
                    
                    NavigationLink(value: "Visualization") {
                        Label {
                            Text("Visualization")
                                .font(.body)
                                .foregroundStyle(.primary)
                        } icon: {
                            Image(systemName: "chart.pie")
                                .symbolRenderingMode(.hierarchical)
                                .foregroundStyle(.red)
                                .fontWeight(.medium)
                        }
                    }
                    .buttonStyle(.plain)
                    .padding(.vertical, 2)
                } header: {
                    Text("Analysis")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .fontWeight(.semibold)
                }
            }
            .listStyle(SidebarListStyle())
            .navigationTitle("Zennic")
            .navigationSplitViewStyle(.automatic)
            .frame(minWidth: 220)
        } detail: {
            Group {
                switch appState.selectedFeature {
                case "CodeEditor":
                    Text("Code Editor")
                        .font(.title)
                case "DataIntegration":
                    Text("Data Integration")
                        .font(.title)
                case "Backtesting":
                    Text("Backtesting")
                        .font(.title)
                case "RealTimeMonitoring":
                    Text("Real-Time Monitoring")
                        .font(.title)
                case "Visualization":
                    Text("Visualization")
                        .font(.title)
                default:
                    VStack(spacing: 12) {
                        Image(systemName: "arrow.left.circle")
                            .font(.system(size: 48))
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.secondary)
                        Text("Select a feature from the sidebar")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button(action: { isShowingSettings = true }) {
                        Image(systemName: "gear")
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.primary)
                            .font(.body)
                    }
                    .help("Settings")
                }
            }
        }
        .preferredColorScheme(appState.isDarkMode ? .dark : .light)
        .sheet(isPresented: $isShowingSettings) {
            SettingsView()
        }
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        _MainView()
            .environmentObject(Core.appState)
    }
}
