import SwiftUI
import Shared
import Core
import CodeEditorInterface

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
private struct SidebarNavigationView: View {
    @Binding var selectedFeature: String?
    
    var body: some View {
        List(selection: $selectedFeature) {
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
private struct FeatureContentView: View {
    @EnvironmentObject var appState: AppState
    @Binding var editorsHeight: CGFloat
    
    var body: some View {
        GeometryReader { geo in
            Group {
                switch appState.selectedFeature {
                case "CodeEditor":
                    CodeEditorContent(workspacePath: appState.workspacePath)
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

private struct CodeEditorContent: View {
    let workspacePath: String
    
    var body: some View {
        Group {
            if !workspacePath.isEmpty {
                CodeEditorFactory.makeEditor(workspacePath: workspacePath)
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

// MARK: - Utility Area
private struct UtilityAreaOverlay: View {
    @ObservedObject var viewModel: UtilityAreaViewModel
    let editorsHeight: CGFloat
    let drawerHeight: CGFloat
    let statusbarHeight: CGFloat
    let proxy: Shared.SplitViewProxy
    
    private var utilityAreaOffset: CGFloat {
        viewModel.isMaximized ? 0 : editorsHeight + 1
    }
    
    private var statusBarOffset: CGFloat {
        viewModel.isMaximized ? 0 : editorsHeight - statusbarHeight
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            UtilityAreaView()
                .frame(height: viewModel.isMaximized ? nil : drawerHeight)
                .frame(maxHeight: viewModel.isMaximized ? .infinity : nil)
                .padding(.top, viewModel.isMaximized ? statusbarHeight + 1 : 0)
                .offset(y: utilityAreaOffset)
            
            VStack(spacing: 0) {
                StatusBarView(proxy: proxy)
                if viewModel.isMaximized {
                    PanelDivider()
                }
            }
            .offset(y: statusBarOffset)
        }
        .accessibilityElement(children: .contain)
    }
}

// MARK: - Main Content Layout
private struct MainContentLayout: View {
    @Binding var editorsHeight: CGFloat
    @Binding var drawerHeight: CGFloat
    @ObservedObject var utilityAreaViewModel: UtilityAreaViewModel
    @ObservedObject var appState: AppState
    let proxy: Shared.SplitViewProxy
    
    private let statusbarHeight: CGFloat = 29
    
    var body: some View {
        Shared.SplitView(axis: .vertical) {
            ZStack {
                FeatureContentView(editorsHeight: $editorsHeight)
            }
            .frame(minHeight: 170 + statusbarHeight + statusbarHeight)
            .collapsible()
            .collapsed($utilityAreaViewModel.isMaximized)
            
            Rectangle()
                .collapsible()
                .collapsed($utilityAreaViewModel.isCollapsed)
                .opacity(0)
                .frame(idealHeight: 260)
                .frame(minHeight: 100)
                .background(drawerHeightReader)
                .accessibilityHidden(true)
        }
        .edgesIgnoringSafeArea(.top)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .top) {
            UtilityAreaOverlay(
                viewModel: utilityAreaViewModel,
                editorsHeight: editorsHeight,
                drawerHeight: drawerHeight,
                statusbarHeight: statusbarHeight,
                proxy: proxy
            )
        }
    }
    
    private var drawerHeightReader: some View {
        GeometryReader { geo in
            Rectangle()
                .opacity(0)
                .onChange(of: geo.size.height) { newHeight in
                    drawerHeight = newHeight
                }
                .onAppear {
                    drawerHeight = geo.size.height
                }
        }
    }
}

// MARK: - Main View
public struct _MainView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var utilityAreaViewModel = UtilityAreaViewModel()
    @StateObject private var statusBarViewModel = StatusBarViewModel()
    @State private var columnVisibility = NavigationSplitViewVisibility.automatic
    @State private var editorsHeight: CGFloat = 0
    @State private var drawerHeight: CGFloat = 0
    
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
        let mainContent = NavigationStack {
            Shared.SplitViewReader { proxy in
                VStack(spacing: 0) {
                    ToolbarView()
                        .padding(EdgeInsets(top: 1, leading: 0, bottom: 0, trailing: 0))
                    MainContentLayout(
                    editorsHeight: $editorsHeight,
                    drawerHeight: $drawerHeight,
                    utilityAreaViewModel: utilityAreaViewModel,
                    appState: appState,
                    proxy: proxy
                    )
                }
            }
            .windowTitleBarStyle()
        }
        
        return NavigationSplitView(columnVisibility: $columnVisibility) {
            SidebarNavigationView(selectedFeature: $appState.selectedFeature)
        } detail: {
            mainContent
        }
        .preferredColorScheme(appState.isDarkMode ? .dark : .light)
        .background(EffectView(.contentBackground))
        .environmentObject(utilityAreaViewModel)
        .environmentObject(statusBarViewModel)
    }
}

// MARK: - Previews
struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        _MainView()
            .environmentObject(AppState.shared)
            .environmentObject(StatusBarViewModel())
            .environmentObject(UtilityAreaViewModel())
    }
}
