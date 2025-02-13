//
//  InspectorAreaView.swift
//  zennic
//

import SwiftUI
import Editor
import DocumentsInterface

struct InspectorAreaView<Document: WorkspaceDocumentProtocol>: View {
    @ObservedObject var viewModel: InspectorAreaViewModel
    @ObservedObject var workspace: Document
    @EnvironmentObject var editorManager: EditorManager
    
    init(workspace: Document, viewModel: InspectorAreaViewModel) {
        self.workspace = workspace
        self.viewModel = viewModel
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Inspector toolbar
            HStack(spacing: 0) {
                ForEach(InspectorAreaViewModel.InspectorTab.allCases, id: \.rawValue) { tab in
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
            
            // Inspector content
            Group {
                switch viewModel.selectedTab {
                case .file:
                    FileInspectorView(viewModel: viewModel)
                case .history:
                    HistoryInspectorView(viewModel: viewModel)
                }
            }
        }
    }
}

// MARK: - File Inspector
struct FileInspectorView: View {
    @ObservedObject var viewModel: InspectorAreaViewModel
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // File info section
                Section {
                    ForEach(Array(viewModel.fileInfo.sorted(by: { $0.key < $1.key })), id: \.key) { key, value in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(key)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(value)
                                .textSelection(.enabled)
                        }
                    }
                } header: {
                    Text("File Info")
                        .font(.headline)
                }
                
                if viewModel.fileInfo.isEmpty {
                    Text("No file selected")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .padding()
        }
    }
}

// MARK: - History Inspector
struct HistoryInspectorView: View {
    @ObservedObject var viewModel: InspectorAreaViewModel
    
    var body: some View {
        List {
            if viewModel.historyItems.isEmpty {
                Text("No history available")
                    .foregroundColor(.secondary)
            } else {
                ForEach(viewModel.historyItems, id: \.self) { item in
                    Text(item)
                }
            }
        }
        .listStyle(.sidebar)
    }
}

#Preview {
    InspectorAreaView(
        workspace: WorkspaceDocument(),
        viewModel: InspectorAreaViewModel()
    )
    .frame(width: 280, height: 600)
    .environmentObject(EditorManager())
}
