import SwiftUI
import Core

public struct GitView: View {
    @State private var selectedTab = 0
    @State private var branches: [String] = []
    @State private var currentBranch = ""
    @State private var status: [GitStatus] = []
    @State private var selectedFile: String?
    @State private var diff: String = ""
    @State private var history: [GitCommit] = []
    @State private var commitMessage = ""
    @State private var showNewBranchSheet = false
    @State private var newBranchName = ""
    @State private var error: Error?
    
    private let gitService: GitService
    private let path: String
    
    public init(path: String) throws {
        self.path = path
        self.gitService = try GitService(path: path)
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Branch selector and controls
            HStack {
                Menu {
                    ForEach(branches, id: \.self) { branch in
                        Button(action: {
                            switchBranch(to: branch)
                        }) {
                            HStack {
                                Text(branch)
                                if branch == currentBranch {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                    
                    Divider()
                    
                    Button("New Branch...") {
                        showNewBranchSheet = true
                    }
                } label: {
                    HStack {
                        Image(systemName: "arrow.triangle.branch")
                        Text(currentBranch)
                        Image(systemName: "chevron.down")
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(6)
                }
                
                Spacer()
                
                Button(action: refresh) {
                    Image(systemName: "arrow.clockwise")
                }
                .help("Refresh")
            }
            .padding()
            
            Divider()
            
            // Main content
            TabView(selection: $selectedTab) {
                // Changes tab
                VStack {
                    List(status, id: \.file, selection: $selectedFile) { item in
                        HStack {
                            Image(systemName: statusIcon(for: item.state))
                                .foregroundColor(statusColor(for: item.state))
                            VStack(alignment: .leading) {
                                Text(item.file)
                                Text(item.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    if !status.isEmpty {
                        VStack(spacing: 8) {
                            TextField("Commit message", text: $commitMessage)
                                .textFieldStyle(.roundedBorder)
                            
                            Button("Commit Changes") {
                                commitChanges()
                            }
                            .disabled(commitMessage.isEmpty)
                            .keyboardShortcut(.return, modifiers: .command)
                        }
                        .padding()
                    }
                }
                .tabItem {
                    Label("Changes", systemImage: "dot.radiowaves.left.and.right")
                }
                .tag(0)
                
                // Diff viewer tab
                ScrollView {
                    if selectedFile != nil {
                        Text(diff)
                            .font(.system(.body, design: .monospaced))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                    } else {
                        Text("Select a file to view diff")
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .tabItem {
                    Label("Diff", systemImage: "arrow.left.and.right")
                }
                .tag(1)
                
                // History tab
                List(history, id: \.message) { commit in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(commit.message)
                            .font(.headline)
                        HStack {
                            Text(commit.author)
                                .font(.system(.caption, design: .monospaced))
                            Text("•")
                            Text(commit.timestamp, style: .date)
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
                .tabItem {
                    Label("History", systemImage: "clock")
                }
                .tag(2)
            }
        }
        .alert(
            "Error",
            isPresented: Binding(
                get: { error != nil },
                set: { _ in error = nil }
            ),
            actions: {
                Button("OK", role: .cancel) {}
            },
            message: {
                if let error = error {
                    Text(error.localizedDescription)
                }
            }
        )
        .sheet(isPresented: $showNewBranchSheet) {
            NavigationView {
                Form {
                    TextField("Branch name", text: $newBranchName)
                }
                .navigationTitle("New Branch")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            showNewBranchSheet = false
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Create") {
                            createBranch()
                            showNewBranchSheet = false
                        }
                        .disabled(newBranchName.isEmpty)
                    }
                }
            }
            .frame(width: 300, height: 150)
        }
        .onAppear {
            refresh()
        }
        .onChange(of: selectedFile) { _ in
            updateDiff()
        }
    }
    
    private func refresh() {
        do {
            branches = try gitService.getBranches()
            currentBranch = try gitService.getCurrentBranch()
            status = try gitService.getStatus()
            if let file = selectedFile {
                history = try gitService.getHistory(for: file)
            }
            updateDiff()
        } catch let error as GitError {
            self.error = error
        } catch {
            self.error = GitError.statusFailed
        }
    }
    
    private func updateDiff() {
        guard let file = selectedFile else { return }
        do {
            diff = try gitService.getDiff(for: file)
        } catch let error as GitError {
            self.error = error
        } catch {
            self.error = GitError.diffFailed
        }
    }
    
    private func switchBranch(to branch: String) {
        do {
            try gitService.checkoutBranch(name: branch)
            refresh()
        } catch let error as GitError {
            self.error = error
        } catch {
            self.error = GitError.branchFailed
        }
    }
    
    private func createBranch() {
        do {
            try gitService.createBranch(name: newBranchName)
            newBranchName = ""
            refresh()
        } catch let error as GitError {
            self.error = error
        } catch {
            self.error = GitError.branchFailed
        }
    }
    
    private func commitChanges() {
        do {
            try gitService.commit(message: commitMessage)
            commitMessage = ""
            refresh()
        } catch let error as GitError {
            self.error = error
        } catch {
            self.error = GitError.commitFailed
        }
    }
    
    private func statusIcon(for state: String) -> String {
        switch state {
        case "Modified": return "pencil"
        case "Untracked": return "questionmark"
        case "Added": return "plus"
        case "Deleted": return "minus"
        case "Renamed": return "arrow.right"
        case "Copied": return "doc.on.doc"
        case "Updated": return "arrow.up"
        default: return "circle"
        }
    }
    
    private func statusColor(for state: String) -> Color {
        switch state {
        case "Modified": return .yellow
        case "Untracked": return .gray
        case "Added": return .green
        case "Deleted": return .red
        case "Renamed": return .blue
        case "Copied": return .purple
        case "Updated": return .orange
        default: return .primary
        }
    }
}

/// A container view that handles the throwing initialization of GitView
private struct GitViewContainer: View {
    let path: String
    @State private var view: AnyView?
    @State private var error: Error?
    
    var body: some View {
        Group {
            if let view = view {
                view
            } else if let error = error {
                Text("Error: \(error.localizedDescription)")
            } else {
                Text("Loading...")
            }
        }
        .onAppear {
            do {
                self.view = AnyView(try GitView(path: path))
            } catch {
                self.error = error
            }
        }
    }
}

#Preview {
    GitViewContainer(path: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("ZennicCode").path)
}
