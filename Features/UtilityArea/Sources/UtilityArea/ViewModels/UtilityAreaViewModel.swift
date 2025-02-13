//
//  UtilityAreaViewModel.swift
//  UtilityArea
//
//  Created by Claude on 2/11/25.
//

import SwiftUI
import DocumentsInterface
import TerminalEmulator

/// A model class to host and manage data for the Utility area.
public final class UtilityAreaViewModel: ObservableObject {
    /// The currently selected tab.
    @Published public var selectedTab: UtilityAreaTab? = .terminal

    /// The list of active terminals.
    @Published public var terminals: [UtilityAreaTerminal] = []

    /// The set of selected terminal IDs.
    @Published public var selectedTerminals: Set<UtilityAreaTerminal.ID> = []

    /// Indicates whether debugger is collapsed or not.
    @Published public var isCollapsed: Bool = false

    /// Returns true when the drawer is visible.
    @Published public var isMaximized: Bool = false

    /// The current height of the drawer. Zero if hidden.
    @Published public var currentHeight: Double = 0

    /// The tab bar items for the UtilityAreaView.
    @Published public var tabItems: [UtilityAreaTab] = UtilityAreaTab.allCases

    /// The tab bar view model for UtilityAreaTabView.
    @Published public var tabViewModel = UtilityAreaTabViewModel()

    public init() {}

    // MARK: - State Restoration

    /// Restore state from workspace document.
    /// - Parameter workspace: The workspace document.
    public func restoreFromState(_ workspace: any WorkspaceDocumentProtocol) {
        isCollapsed = workspace.getFromWorkspaceState(.utilityAreaCollapsed) as? Bool ?? false
        currentHeight = workspace.getFromWorkspaceState(.utilityAreaHeight) as? Double ?? 300.0
        isMaximized = workspace.getFromWorkspaceState(.utilityAreaMaximized) as? Bool ?? false
    }

    /// Save state to workspace document.
    /// - Parameter workspace: The workspace document.
    public func saveRestorationState(_ workspace: any WorkspaceDocumentProtocol) {
        workspace.addToWorkspaceState(key: .utilityAreaCollapsed, value: isCollapsed as Any)
        workspace.addToWorkspaceState(key: .utilityAreaHeight, value: currentHeight as Any)
        workspace.addToWorkspaceState(key: .utilityAreaMaximized, value: isMaximized as Any)
    }

    /// Toggle the utility area panel.
    public func togglePanel() {
        self.isMaximized = false
        self.isCollapsed.toggle()
    }

    // MARK: - Terminal Management

    /// Removes all terminals included in the given set and selects a new terminal if the selection was modified.
    /// The new selection is either the same selection minus the ids removed, or if that's empty the last terminal.
    /// - Parameter ids: A set of all terminal ids to remove.
    public func removeTerminals(_ ids: Set<UUID>) {
        for (idx, terminal) in terminals.enumerated().reversed()
        where ids.contains(terminal.id) {
            TerminalCache.shared.removeCachedView(terminal.id)
            terminals.remove(at: idx)
        }

        var newSelection = selectedTerminals.subtracting(ids)

        if newSelection.isEmpty, let terminal = terminals.last {
            newSelection = [terminal.id]
        }

        selectedTerminals = newSelection
    }

    /// Update a terminal's title.
    /// - Parameters:
    ///   - id: The id of the terminal to update.
    ///   - title: The title to set. If left `nil`, will set the terminal's
    ///            ``UtilityAreaTerminal/customTitle`` to `false`.
    public func updateTerminal(_ id: UUID, title: String?) {
        guard let terminal = terminals.first(where: { $0.id == id }) else { return }
        if let newTitle = title {
            if !terminal.customTitle {
                terminal.title = newTitle
            }
            terminal.terminalTitle = newTitle
        } else {
            terminal.customTitle = false
        }
    }

    /// Create a new terminal if there are no existing terminals.
    /// Will not perform any action if terminals exist in the ``terminals`` array.
    /// - Parameter workspaceURL: The base url of the workspace, to initialize terminals.
    public func initializeTerminals(workspaceURL: URL) {
        guard terminals.isEmpty else { return }
        addTerminal(rootURL: workspaceURL)
    }

    /// Add a new terminal to the workspace and selects it.
    /// - Parameters:
    ///   - shell: The shell to use, `nil` if auto-detect the default shell.
    ///   - rootURL: The url to start the new terminal at. If left `nil` defaults to the user's home directory.
    public func addTerminal(shell: Shell? = nil, rootURL: URL?) {
        let id = UUID()

        terminals.append(
            UtilityAreaTerminal(
                id: id,
                url: rootURL ?? URL(filePath: "~/"),
                title: shell?.rawValue ?? "terminal",
                shell: shell
            )
        )

        selectedTerminals = [id]
    }

    /// Replaces the terminal with a given ID, killing the shell and restarting it at the same directory.
    ///
    /// Terminals being replaced will have the `SIGKILL` signal sent to the running shell. The new terminal will
    /// inherit the same `url` and `shell` parameters from the old one.
    /// - Parameter replacing: The ID of a terminal to replace with a new terminal.
    public func replaceTerminal(_ replacing: UUID) {
        guard let index = terminals.firstIndex(where: { $0.id == replacing }) else {
            return
        }

        let id = UUID()
        let url = terminals[index].url
        let shell = terminals[index].shell
        if let shellPid = TerminalCache.shared.getTerminalView(replacing)?.process.shellPid {
            kill(shellPid, SIGKILL)
        }

        terminals[index] = UtilityAreaTerminal(
            id: id,
            url: url,
            title: shell?.rawValue ?? "terminal",
            shell: shell
        )
        TerminalCache.shared.removeCachedView(replacing)

        selectedTerminals = [id]
        return
    }

    /// Reorders terminals in the ``utilityAreaViewModel``.
    /// - Parameters:
    ///   - source: The source indices.
    ///   - destination: The destination indices.
    public func reorderTerminals(from source: IndexSet, to destination: Int) {
        terminals.move(fromOffsets: source, toOffset: destination)
    }
}
