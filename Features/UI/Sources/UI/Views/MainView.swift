//
//  MainView.swift
//  UI
//

import SwiftUI
import Shared
import Core
import CodeEditorInterface
import DocumentsInterface

// Use Shared module's SplitView components
typealias SplitViewProxy = Shared.SplitViewProxy

// MARK: - Navigation Link Components
private struct SidebarNavigationLink<Icon: View>: View {
    let value: String
    let title: String
    let icon: Icon
    
    var body: some View {
        NavigationLink(value: value) {
            Label {
                Text(title)
                    .font(.body)
                    .foregroundStyle(.primary)
            } icon: {
                icon
            }
        }
        .buttonStyle(.plain)
        .padding(.vertical, 2)
    }
}

// MARK: - Sidebar Sections
private struct DevelopmentSection: View {
    var body: some View {
        Section {
            SidebarNavigationLink(
                value: "CodeEditor",
                title: "Code Editor",
                icon: Image(systemName: "doc.text")
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.blue)
                    .fontWeight(.medium)
            )
            
            SidebarNavigationLink(
                value: "DataIntegration",
                title: "Data Integration",
                icon: Image(systemName: "arrow.triangle.2.circlepath")
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.green)
                    .fontWeight(.medium)
            )
        } header: {
            Text("Development")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fontWeight(.semibold)
        }
    }
}

private struct AnalysisSection: View {
    var body: some View {
        Section {
            SidebarNavigationLink(
                value: "Backtesting",
                title: "Backtesting",
                icon: Image(systemName: "chart.xyaxis.line")
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.purple)
                    .fontWeight(.medium)
            )
            
            SidebarNavigationLink(
                value: "RealTimeMonitoring",
                title: "Real-Time Monitoring",
                icon: Image(systemName: "chart.bar.xaxis")
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.orange)
                    .fontWeight(.medium)
            )
            
            SidebarNavigationLink(
                value: "Visualization",
                title: "Visualization",
                icon: Image(systemName: "chart.pie")
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.red)
                    .fontWeight(.medium)
            )
        } header: {
            Text("Analysis")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fontWeight(.semibold)
        }
    }
}

private struct SettingsSection: View {
    var body: some View {
        Section {
            SidebarNavigationLink(
                value: "Settings",
                title: "Settings",
                icon: Image(systemName: "gear")
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.gray)
                    .fontWeight(.medium)
            )
        }
    }
}

// MARK: - Sidebar Navigation
private struct SidebarNavigationView<Document: WorkspaceDocumentProtocol>: View {
    @EnvironmentObject var workspace: Document
    
    var body: some View {
        List(selection: $workspace.selectedFeature) {
            DevelopmentSection()
            AnalysisSection()
            SettingsSection()
        }
        .listStyle(SidebarListStyle())
        .navigationTitle("Zennic")
        .navigationSplitViewStyle(.automatic)
        .frame(minWidth: 220)
    }
}

// MARK: - Feature Content
private struct FeatureContentView<Document: WorkspaceDocumentProtocol>: View {
    @EnvironmentObject var workspace: Document
    @Binding var editorsHeight: CGFloat
    
    var body: some View {
        GeometryReader { geo in
            Group {
                switch workspace.selectedFeature {
                case "CodeEditor":
                    CodeEditorContent(workspace: workspace)
                case "DataIntegration", "Backtesting", "RealTimeMonitoring", "Visualization":
                    EmptyView()
                case "Settings":
                    SettingsView()
                default:
                    DefaultContent()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onChange(of: geo.size.height) { newHeight in
                editorsHeight = newHeight
            }
            .onAppear {
                editorsHeight = geo.size.height
            }
        }
    }
}

private struct CodeEditorContent<Document: WorkspaceDocumentProtocol>: View {
    @ObservedObject var workspace: Document
    
    var body: some View {
        Group {
            if let fileManager = workspace.workspaceFileManager {
                CodeEditorFactory.makeEditor(workspacePath: fileManager.folderUrl.path)
            } else {
                EmptyWorkspaceContent()
            }
        }
    }
}

private struct EmptyWorkspaceContent: View {
    var body: some View {
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

private struct DefaultContent: View {
    var body: some View {
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

// MARK: - Workspace Toolbar View
private struct WorkspaceToolbarView<Document: WorkspaceDocumentProtocol>: View {
    @EnvironmentObject var workspace: Document
    
    var body: some View {
        HStack {
            // TODO: Implement toolbar
            Text("Toolbar")
        }
        .frame(height: 28)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

// MARK: - Main Content Layout
private struct MainContentLayout<Document: WorkspaceDocumentProtocol>: View {
    @Binding var editorsHeight: CGFloat
    @ObservedObject var utilityAreaViewModel: UtilityAreaViewModel
    @ObservedObject var workspace: Document
    let proxy: Shared.SplitViewProxy
    
    private let statusbarHeight: CGFloat = 29
    
    var body: some View {
        Shared.SplitView(axis: .vertical) {
            ZStack {
                FeatureContentView<Document>(editorsHeight: $editorsHeight)
            }
            .frame(minHeight: 170 + statusbarHeight)
            .canCollapse()
            .collapsed($utilityAreaViewModel.isMaximized)
            
            VStack(spacing: 0) {
                Divider()
                UtilityAreaView()
                    .environmentObject(utilityAreaViewModel)
            }
            .frame(idealHeight: 300)
            .frame(minHeight: 100)
            .canCollapse()
            .collapsed($utilityAreaViewModel.isCollapsed)
        }
        .edgesIgnoringSafeArea(.top)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .bottom) {
            StatusBarView(proxy: proxy)
                .frame(height: statusbarHeight)
        }
    }
}

// MARK: - Main View
public struct _MainView<Document: WorkspaceDocumentProtocol>: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var workspace: Document
    @StateObject private var utilityAreaViewModel = UtilityAreaViewModel()
    @StateObject private var statusBarViewModel = StatusBarViewModel()
    @State private var columnVisibility = NavigationSplitViewVisibility.automatic
    @State private var editorsHeight: CGFloat = 0
    
    private var navigationTitle: String {
        switch workspace.selectedFeature {
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
            SidebarNavigationView<Document>()
        } detail: {
            NavigationStack {
                Shared.SplitViewReader { proxy in
                    VStack(spacing: 0) {
                        WorkspaceToolbarView<Document>()
                            .padding(EdgeInsets(top: 1, leading: 0, bottom: 0, trailing: 0))
                        MainContentLayout(
                            editorsHeight: $editorsHeight,
                            utilityAreaViewModel: utilityAreaViewModel,
                            workspace: workspace,
                            proxy: proxy
                        )
                    }
                }
                .windowTitleBarStyle()
            }
        }
        .preferredColorScheme(appState.isDarkMode ? .dark : .light)
        .background(EffectView(.contentBackground))
        .environmentObject(utilityAreaViewModel)
        .environmentObject(statusBarViewModel)
    }
}

#if DEBUG
// MARK: - Previews
private class PreviewWorkspaceDocument: WorkspaceDocumentProtocol {
    @Published var selectedFeature: String?
    var workspaceFileManager: CEWorkspaceFileManager?
    
    func getFromWorkspaceState(_ key: WorkspaceStateKey) -> Any? { nil }
    func addToWorkspaceState(key: WorkspaceStateKey, value: Any?) {}
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        let workspace = PreviewWorkspaceDocument()
        workspace.selectedFeature = "CodeEditor"
        
        return _MainView<PreviewWorkspaceDocument>()
            .environmentObject(AppState.shared)
            .environmentObject(workspace)
            .environmentObject(StatusBarViewModel())
            .environmentObject(UtilityAreaViewModel())
    }
}
#endif
