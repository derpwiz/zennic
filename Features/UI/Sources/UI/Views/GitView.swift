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
    
    private let gitService = Core.GitService.shared
    private let path: String
    
    public init(path: String) {
        self.path = path
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
                List(history, id: \.hash) { commit in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(commit.message)
                            .font(.headline)
                        HStack {
                            Text(commit.hash)
                                .font(.system(.caption, design: .monospaced))
                            Text("•")
                            Text(commit.author)
                            Text("•")
                            Text(commit.date)
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
            branches = try gitService.getBranches(at: path)
            currentBranch = try gitService.getCurrentBranch(at: path)
            status = try gitService.getStatus(at: path)
            if let file = selectedFile {
                history = try gitService.getFileHistory(file: file, at: path)
            }
            updateDiff()
        } catch let error as Core.GitError {
            self.error = error
        } catch {
            self.error = Core.GitError.statusFailed
        }
    }
    
    private func updateDiff() {
        guard let file = selectedFile else { return }
        do {
            diff = try gitService.getDiff(file: file, at: path)
        } catch let error as Core.GitError {
            self.error = error
        } catch {
            self.error = Core.GitError.diffFailed
        }
    }
    
    private func switchBranch(to branch: String) {
        do {
            try gitService.checkoutBranch(name: branch, at: path)
            refresh()
        } catch let error as Core.GitError {
            self.error = error
        } catch {
            self.error = Core.GitError.branchFailed
        }
    }
    
    private func createBranch() {
        do {
            try gitService.createBranch(name: newBranchName, at: path)
            newBranchName = ""
            refresh()
        } catch let error as Core.GitError {
            self.error = error
        } catch {
            self.error = Core.GitError.branchFailed
        }
    }
    
    private func commitChanges() {
        do {
            try gitService.commit(message: commitMessage, at: path)
            commitMessage = ""
            refresh()
        } catch let error as Core.GitError {
            self.error = error
        } catch {
            self.error = Core.GitError.commitFailed
        }
    }
    
    private func statusIcon(for state: String) -> String {
        switch state {
        case "M": return "pencil"
        case "A": return "plus"
        case "D": return "minus"
        case "R": return "arrow.right"
        case "C": return "doc.on.doc"
        case "U": return "arrow.up"
        case "??": return "questionmark"
        default: return "circle"
        }
    }
    
    private func statusColor(for state: String) -> Color {
        switch state {
        case "M": return .yellow
        case "A": return .green
        case "D": return .red
        case "R": return .blue
        case "C": return .purple
        case "U": return .orange
        case "??": return .gray
        default: return .primary
        }
    }
}

#Preview {
    GitView(path: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("ZennicCode").path)
}
