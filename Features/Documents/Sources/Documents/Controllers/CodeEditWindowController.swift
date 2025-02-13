//
//  CodeEditWindowController.swift
//  zennic
//

import Cocoa
import SwiftUI
import Combine
import DocumentsInterface
import Editor
import UtilityArea
import CodeEditorInterface

final class CodeEditWindowController: NSWindowController, NSToolbarDelegate, ObservableObject, NSWindowDelegate {
    @Published var navigatorCollapsed = false
    @Published var inspectorCollapsed = false
    @Published var toolbarCollapsed = false

    private var panelOpen = false

    var observers: [NSKeyValueObservation] = []

    var workspace: WorkspaceDocument?
    var workspaceSettingsWindow: NSWindow?
    var quickOpenPanel: SearchPanel?
    var commandPalettePanel: SearchPanel?
    var navigatorSidebarViewModel: NavigatorAreaViewModel?

    internal var cancellables = [AnyCancellable]()

    var splitViewController: CodeEditSplitViewController? {
        contentViewController as? CodeEditSplitViewController
    }

    init(
        window: NSWindow?,
        workspace: WorkspaceDocument?
    ) {
        super.init(window: window)
        window?.delegate = self
        guard let workspace else { return }
        self.workspace = workspace
        guard let splitViewController = setupSplitView(with: workspace) else {
            fatalError("Failed to set up content view.")
        }

        contentViewController = splitViewController

        observers = [
            splitViewController.splitViewItems.first!.observe(\.isCollapsed) { [weak self] object, change in
                if let newValue = change.newValue {
                    self?.navigatorCollapsed = newValue
                }
            },
            splitViewController.splitViewItems.last!.observe(\.isCollapsed) { [weak self] object, change in
                if let newValue = change.newValue {
                    self?.inspectorCollapsed = newValue
                }
            }
        ]

        setupToolbar()
        registerCommands()
    }

    deinit {
        cancellables.forEach({ $0.cancel() })
        cancellables.removeAll()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupSplitView(with workspace: WorkspaceDocument) -> CodeEditSplitViewController? {
        guard let window else {
            assertionFailure("No window found for this controller. Cannot set up content.")
            return nil
        }

        let navigatorModel = NavigatorAreaViewModel()
        navigatorSidebarViewModel = navigatorModel
        self.listenToDocumentEdited(workspace: workspace)
        let splitViewController = CodeEditSplitViewController(
            workspace: workspace,
            navigatorViewModel: navigatorModel,
            windowRef: window
        )
        return splitViewController
    }

    private func getSelectedCodeFile() -> CodeFileDocument? {
        workspace?.editorManager?.activeEditor?.selectedTab?.file.fileDocument as? CodeFileDocument
    }

    @IBAction func saveDocument(_ sender: Any) {
        guard let codeFile = getSelectedCodeFile() else { return }
        codeFile.save(sender)
        workspace?.editorManager?.activeEditor?.temporaryTab = nil
    }

    @IBAction func openCommandPalette(_ sender: Any) {
        if let workspace, let state = workspace.commandsPaletteState {
            if let commandPalettePanel {
                if commandPalettePanel.isKeyWindow {
                    commandPalettePanel.close()
                    self.panelOpen = false
                    state.reset()
                    return
                } else {
                    state.reset()
                    window?.addChildWindow(commandPalettePanel, ordered: .above)
                    commandPalettePanel.makeKeyAndOrderFront(self)
                    self.panelOpen = true
                }
            } else {
                let panel = SearchPanel()
                self.commandPalettePanel = panel
                let contentView = QuickActionsView(state: state) {
                    panel.close()
                    self.panelOpen = false
                }
                panel.contentView = NSHostingView(rootView: SettingsInjector { contentView })
                window?.addChildWindow(panel, ordered: .above)
                panel.makeKeyAndOrderFront(self)
                self.panelOpen = true
            }
        }
    }

    @IBAction func openQuickly(_ sender: Any?) {
        if let workspace, let state = workspace.openQuicklyViewModel {
            if let quickOpenPanel {
                if quickOpenPanel.isKeyWindow {
                    quickOpenPanel.close()
                    self.panelOpen = false
                    return
                } else {
                    window?.addChildWindow(quickOpenPanel, ordered: .above)
                    quickOpenPanel.makeKeyAndOrderFront(self)
                    self.panelOpen = true
                }
            } else {
                let panel = SearchPanel()
                self.quickOpenPanel = panel

                let contentView = OpenQuicklyView(state: state) {
                    panel.close()
                    self.panelOpen = false
                } openFile: { [weak self] (file: DocumentsInterface.CEWorkspaceFile) in
                    guard let self = self,
                          let workspace = self.workspace,
                          let editor = workspace.editorManager?.activeEditor else { return }
                    editor.openTab(file: file)
                }.environmentObject(workspace)

                panel.contentView = NSHostingView(rootView: SettingsInjector { contentView })
                window?.addChildWindow(panel, ordered: .above)
                panel.makeKeyAndOrderFront(self)
                self.panelOpen = true
            }
        }
    }

    @IBAction func closeCurrentTab(_ sender: Any) {
        if self.panelOpen { return }
        if (workspace?.editorManager?.activeEditor?.tabs ?? []).isEmpty {
            self.closeActiveEditor(self)
        } else {
            workspace?.editorManager?.activeEditor?.closeSelectedTab()
        }
    }

    @IBAction func closeActiveEditor(_ sender: Any) {
        guard let workspace = self.workspace,
              let editorManager = workspace.editorManager,
              let activeEditor = editorManager.activeEditor else { return }
        
        if editorManager.editorLayout.findSomeEditor(except: activeEditor) == nil {
            NSApp.sendAction(#selector(NSWindow.performClose(_:)), to: NSApp.keyWindow, from: nil)
        } else {
            activeEditor.close()
        }
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        cancellables.forEach({ $0.cancel() })
        cancellables.removeAll()

        for _ in 0..<(splitViewController?.children.count ?? 0) {
            splitViewController?.removeChild(at: 0)
        }
        contentViewController?.removeFromParent()
        contentViewController = nil

        workspaceSettingsWindow?.close()
        workspaceSettingsWindow = nil
        quickOpenPanel = nil
        commandPalettePanel = nil
        navigatorSidebarViewModel = nil
        workspace = nil
        return true
    }

    // MARK: - Private Methods

    private func setupToolbar() {
        // TODO: Implement toolbar setup
    }

    private func registerCommands() {
        // TODO: Implement command registration
    }

    private func listenToDocumentEdited(workspace: WorkspaceDocument) {
        // TODO: Implement document edited listener
    }
}
