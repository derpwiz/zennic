import SwiftUI
import Shared
import Core
import CodeEditorInterface

public struct _MainView: View {
    @EnvironmentObject var appState: AppState
    @State private var columnVisibility = NavigationSplitViewVisibility.automatic
    @State private var isShowingSettings = false
    
    private var navigationTitle: String {
        switch appState.selectedFeature {
        case "CodeEditor": return "Code Editor"
        case "DataIntegration": return "Data Integration"
        case "Backtesting": return "Backtesting"
        case "RealTimeMonitoring": return "Real-Time Monitoring"
        case "Visualization": return "Visualization"
        case "Settings": return "Settings"
        default: return "Zennic"
        }
    }
    
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
                
                Section {
                    NavigationLink(value: "Settings") {
                        Label {
                            Text("Settings")
                                .font(.body)
                                .foregroundStyle(.primary)
                        } icon: {
                            Image(systemName: "gear")
                                .symbolRenderingMode(.hierarchical)
                                .foregroundStyle(.gray)
                                .fontWeight(.medium)
                        }
                    }
                    .buttonStyle(.plain)
                    .padding(.vertical, 2)
                }
            }
            .listStyle(SidebarListStyle())
            .navigationTitle("Zennic")
            .navigationSplitViewStyle(.automatic)
            .frame(minWidth: 220)
        } detail: {
            NavigationStack {
                Group {
                    switch appState.selectedFeature {
                    case "CodeEditor":
                        Group {
                            if !appState[keyPath: \.workspacePath].isEmpty {
                                CodeEditorFactory.makeEditor(workspacePath: appState[keyPath: \.workspacePath])
                            } else {
                                VStack(spacing: 12) {
                                    Image(systemName: "folder.badge.plus")
                                        .font(.system(size: 48))
                                        .symbolRenderingMode(.hierarchical)
                                        .foregroundStyle(.secondary)
                                    Text("Please select a workspace path")
                                        .font(.title3)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    case "DataIntegration":
                        EmptyView()
                    case "Backtesting":
                        EmptyView()
                    case "RealTimeMonitoring":
                        EmptyView()
                    case "Visualization":
                        EmptyView()
                    case "Settings":
                        SettingsView()
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
                .navigationTitle(navigationTitle)
            }
        }
        .preferredColorScheme(appState.isDarkMode ? .dark : .light)
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        _MainView()
            .environmentObject(AppState.shared)
    }
}
