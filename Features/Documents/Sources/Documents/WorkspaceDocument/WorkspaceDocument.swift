//
//  WorkspaceDocument.swift
//  Documents
//
//  Created by Claude on 2/11/25.
//

import AppKit
import SwiftUI
import Combine
import Foundation
import Editor
import UtilityArea
import CodeEditorInterface
import DocumentsInterface
import UniformTypeIdentifiers

@objc(WorkspaceDocument)
public final class WorkspaceDocument: ReferenceFileDocument {
    public static var readableContentTypes: [UTType] { [.zennicWorkspace] }
    
    @Published public var sortFoldersOnTop: Bool = true
    @Published public var navigatorFilter: String = ""
    @Published public var selectedFeature: String?

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

    public var workspaceFileManager: CEWorkspaceFileManager?
    public var editorManager: EditorManager? = EditorManager()
    public var statusBarViewModel: StatusBarViewModel? = StatusBarViewModel()
    public var utilityAreaModel: UtilityAreaViewModel? = UtilityAreaViewModel()

    private var cancellables = Set<AnyCancellable>()
    
    public var fileURL: URL?

    public init() {
        super.init()
    }
    
    public required init(configuration: ReadConfiguration) throws {
        try initWorkspaceState(configuration.file.url)
    }
    
    public func snapshot(contentType: UTType) throws -> WorkspaceDocument {
        self
    }
    
    public func fileWrapper(snapshot: WorkspaceDocument, configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(directoryWithFileWrappers: [:])
    }

    deinit {
        cancellables.forEach { $0.cancel() }
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: Document Management

    private let ignoredFilesAndDirectory = [
        ".DS_Store"
    ]

    public var isDocumentEdited: Bool {
        false
    }

    public func makeWindowControllers() {
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
        self.workspaceFileManager = .init(
            folderUrl: url,
            ignoredFilesAndFolders: Set(ignoredFilesAndDirectory)
        )

        editorManager?.restoreFromState(self)
        utilityAreaModel?.restoreFromState(self)
    }

    // MARK: Close Workspace

    public func close() {
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
    public func shouldCloseWindowController(
        _ windowController: NSWindowController,
        delegate: Any?,
        shouldClose shouldCloseSelector: Selector?,
        contextInfo: UnsafeMutableRawPointer?
    ) {
        guard let object = (delegate as? NSObject),
              let shouldCloseSelector = shouldCloseSelector,
              let contextInfo = contextInfo
        else {
            return
        }
        // Save unsaved changes before closing
        let editedCodeFiles = editorManager?.gatherOpenFiles()
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
        let areAllOpenedCodeFilesClean = editorManager?.gatherOpenFiles()
            .compactMap(\.fileDocument)
            .allSatisfy { !$0.isDocumentEdited } ?? false
        function(object, shouldCloseSelector, self, areAllOpenedCodeFilesClean, contextInfo)
    }

    // MARK: Document delegate

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

// MARK: - WorkspaceDocumentProtocol

extension WorkspaceDocument: WorkspaceDocumentProtocol {
    public func getFromWorkspaceState(_ key: WorkspaceStateKey) -> Any? {
        workspaceState[key.rawValue]
    }

    public func addToWorkspaceState(key: WorkspaceStateKey, value: Any?) {
        if let value = value {
            workspaceState[key.rawValue] = value
        } else {
            workspaceState.removeValue(forKey: key.rawValue)
        }
    }
}
