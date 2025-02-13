//
//  NavigatorAreaView.swift
//  zennic
//

import SwiftUI
import Editor
import DocumentsInterface

struct NavigatorAreaView: View {
    @ObservedObject var workspace: any WorkspaceDocumentProtocol
    @ObservedObject var viewModel: NavigatorAreaViewModel
    @EnvironmentObject var editorManager: EditorManager
    
    var body: some View {
        VStack(spacing: 0) {
            // Navigator toolbar
            HStack(spacing: 0) {
                ForEach(NavigatorAreaViewModel.NavigatorTab.allCases, id: \.rawValue) { tab in
                    Button {
                        viewModel.selectedTab = tab
                    } label: {
                        Image(systemName: tab.systemImage)
                            .frame(width: 28, height: 28)
                    }
                    .buttonStyle(.plain)
                    .background(viewModel.selectedTab == tab ? Color.accentColor.opacity(0.2) : Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .padding(.horizontal, 4)
                    .help(tab.title)
                }
                Spacer()
            }
            .padding(.vertical, 4)
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            // Navigator content
            Group {
                switch viewModel.selectedTab {
                case .project:
                    ProjectNavigatorView(workspace: workspace, viewModel: viewModel)
                case .sourceControl:
                    SourceControlNavigatorView(workspace: workspace, viewModel: viewModel)
                case .find:
                    FindNavigatorView(workspace: workspace, viewModel: viewModel)
                }
            }
        }
    }
}

// MARK: - Project Navigator
struct ProjectNavigatorView: View {
    @ObservedObject var workspace: any WorkspaceDocumentProtocol
    @ObservedObject var viewModel: NavigatorAreaViewModel
    
    var body: some View {
        List(selection: $viewModel.selectedItems) {
            // TODO: Implement project file tree
            Text("Project Navigator")
        }
        .listStyle(.sidebar)
    }
}

// MARK: - Source Control Navigator
struct SourceControlNavigatorView: View {
    @ObservedObject var workspace: any WorkspaceDocumentProtocol
    @ObservedObject var viewModel: NavigatorAreaViewModel
    
    var body: some View {
        List {
            // TODO: Implement source control view
            Text("Source Control Navigator")
        }
        .listStyle(.sidebar)
    }
}

// MARK: - Find Navigator
struct FindNavigatorView: View {
    @ObservedObject var workspace: any WorkspaceDocumentProtocol
    @ObservedObject var viewModel: NavigatorAreaViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            // Search field
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search", text: $viewModel.searchText)
                    .textFieldStyle(.plain)
                if !viewModel.searchText.isEmpty {
                    Button {
                        viewModel.searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(8)
            
            Divider()
            
            // Search results
            List {
                // TODO: Implement search results
                Text("Find Navigator")
            }
            .listStyle(.sidebar)
        }
    }
}

#Preview {
    NavigatorAreaView(
        workspace: WorkspaceDocument(),
        viewModel: NavigatorAreaViewModel()
    )
    .frame(width: 280, height: 600)
    .environmentObject(EditorManager())
}
