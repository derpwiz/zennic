//
//  WorkspaceDocument.swift
//  zennic
//
//  Created by Claude on 2/11/25.
//

import AppKit
import SwiftUI
import Combine
import Foundation

@objc(WorkspaceDocument)
final class WorkspaceDocument: NSDocument, ObservableObject {
    @Published var sortFoldersOnTop: Bool = true
    @Published var navigatorFilter: String = ""
    @Published var selectedFeature: String?

    private var workspaceState: [String: Any] {
        get {
            let key = "workspaceState-\(self.fileURL?.absoluteString ?? "")"
            return UserDefaults.standard.object(forKey: key) as? [String: Any] ?? [:]
        }
        set {
            let key = "workspaceState-\(self.fileURL?.absoluteString ?? "")"
            UserDefaults.standard.set(newValue, forKey: key)
        }
    }

    var workspaceFileManager: CEWorkspaceFileManager?
    var editorManager: EditorManager? = EditorManager()
    var statusBarViewModel: StatusBarViewModel? = StatusBarViewModel()
    var utilityAreaModel: UtilityAreaViewModel? = UtilityAreaViewModel()

    private var cancellables = Set<AnyCancellable>()

    deinit {
        cancellables.forEach { $0.cancel() }
        NotificationCenter.default.removeObserver(self)
    }

    func getFromWorkspaceState(_ key: WorkspaceStateKey) -> Any? {
        return workspaceState[key.rawValue]
    }

    func addToWorkspaceState(key: WorkspaceStateKey, value: Any?) {
        if let value {
            workspaceState.updateValue(value, forKey: key.rawValue)
        } else {
            workspaceState.removeValue(forKey: key.rawValue)
        }
    }

    // MARK: NSDocument

    private let ignoredFilesAndDirectory = [
        ".DS_Store"
    ]

    override static var autosavesInPlace: Bool {
        false
    }

    override var isDocumentEdited: Bool {
        false
    }

    override func makeWindowControllers() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1400, height: 900),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        let windowController = CodeEditWindowController(
            window: window,
            workspace: self
        )

        if let rectString = getFromWorkspaceState(.workspaceWindowSize) as? String {
            window.setFrame(NSRectFromString(rectString), display: true, animate: false)
        } else {
            window.setFrame(NSRect(x: 0, y: 0, width: 1400, height: 900), display: true, animate: false)
            window.center()
        }

        window.setAccessibilityIdentifier("workspace")
        window.setAccessibilityDocument(self.fileURL?.absoluteString)

        self.addWindowController(windowController)

        window.makeKeyAndOrderFront(nil)
    }

    // MARK: Set Up Workspace

    private func initWorkspaceState(_ url: URL) throws {
        // Ensure the URL ends with a "/" to prevent certain URL(filePath:relativeTo) initializers from
        // placing the file one directory above our workspace. This quick fix appends a "/" if needed.
        var url = url
        if !url.absoluteString.hasSuffix("/") {
            url = URL(filePath: url.absoluteURL.path(percentEncoded: false) + "/")
        }

        self.fileURL = url
        self.displayName = url.lastPathComponent

        self.workspaceFileManager = .init(
            folderUrl: url,
            ignoredFilesAndFolders: Set(ignoredFilesAndDirectory)
        )

        editorManager?.restoreFromState(self)
        utilityAreaModel?.restoreFromState(self)
    }

    override func read(from url: URL, ofType typeName: String) throws {
        try initWorkspaceState(url)
    }

    override func write(to url: URL, ofType typeName: String) throws {}

    // MARK: Close Workspace

    override func close() {
        super.close()
        editorManager?.saveRestorationState(self)
        utilityAreaModel?.saveRestorationState(self)

        cancellables.forEach({ $0.cancel() })
        statusBarViewModel = nil
        utilityAreaModel = nil
        editorManager = nil
        workspaceFileManager?.cleanUp()
        workspaceFileManager = nil
    }

    /// Determines if the windows should be closed.
    ///
    /// This method iterates all edited documents If there are any edited documents.
    ///
    /// A panel giving the user the choice of canceling, discarding changes, or saving is presented while iteration.
    ///
    /// If the user chooses cancel on the panel, iteration is broken.
    ///
    /// In the last step, `shouldCloseSelector` is called with true if all documents are clean, otherwise false
    ///
    /// - Parameters:
    ///   - windowController: The windowController may be closed.
    ///   - delegate: The object which is a target of `shouldCloseSelector`.
    ///   - shouldClose: The callback which receives result of this method.
    ///   - contextInfo: The additional info which is not used in this method.
    override func shouldCloseWindowController(
        _ windowController: NSWindowController,
        delegate: Any?,
        shouldClose shouldCloseSelector: Selector?,
        contextInfo: UnsafeMutableRawPointer?
    ) {
        guard let object = (delegate as? NSObject),
              let shouldCloseSelector = shouldCloseSelector,
              let contextInfo = contextInfo
        else {
            super.shouldCloseWindowController(
                windowController,
                delegate: delegate,
                shouldClose: shouldCloseSelector,
                contextInfo: contextInfo
            )
            return
        }
        // Save unsaved changes before closing
        let editedCodeFiles = editorManager?.editorLayout
            .gatherOpenFiles()
            .compactMap(\.fileDocument)
            .filter(\.isDocumentEdited) ?? []

        for editedCodeFile in editedCodeFiles {
            let shouldClose = UnsafeMutablePointer<Bool>.allocate(capacity: 1)
            shouldClose.initialize(to: true)
            defer {
                _ = shouldClose.move()
                shouldClose.deallocate()
            }
            // Present a panel giving the user the choice of canceling, discarding changes, or saving.
            editedCodeFile.canClose(
                withDelegate: self,
                shouldClose: #selector(document(_:shouldClose:contextInfo:)),
                contextInfo: shouldClose
            )
            // pointee becomes false when user select cancel
            guard shouldClose.pointee else {
                break
            }
        }
        // Invoke shouldCloseSelector at delegate
        let implementation = object.method(for: shouldCloseSelector)
        let function = unsafeBitCast(
            implementation,
            to: (@convention(c)(Any, Selector, Any, Bool, UnsafeMutableRawPointer?) -> Void).self
        )
        let areAllOpenedCodeFilesClean = editorManager?.editorLayout.gatherOpenFiles()
            .compactMap(\.fileDocument)
            .allSatisfy { !$0.isDocumentEdited } ?? false
        function(object, shouldCloseSelector, self, areAllOpenedCodeFilesClean, contextInfo)
    }

    // MARK: NSDocument delegate

    /// Receives result of `canClose` and then, set `shouldClose` to `contextInfo`'s `pointee`.
    ///
    /// - Parameters:
    ///   - document: The document may be closed.
    ///   - shouldClose: The result of user selection.
    ///      `shouldClose` becomes false if the user selects cancel, otherwise true.
    ///   - contextInfo: The additional info which will be set `shouldClose`.
    ///       `contextInfo` must be `UnsafeMutablePointer<Bool>`.
    @objc
    func document(
        _ document: NSDocument,
        shouldClose: Bool,
        contextInfo: UnsafeMutableRawPointer
    ) {
        let opaquePtr = OpaquePointer(contextInfo)
        let mutablePointer = UnsafeMutablePointer<Bool>(opaquePtr)
        mutablePointer.pointee = shouldClose
    }
}
