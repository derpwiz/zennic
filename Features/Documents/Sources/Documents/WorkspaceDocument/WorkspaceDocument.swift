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

extension UTType {
    static let zennicWorkspace = UTType("com.zennic.workspace") ?? UTType.folder
}

public final class WorkspaceDocument: ReferenceFileDocument {
    public static var readableContentTypes: [UTType] { [.zennicWorkspace] }
    
    @Published public var sortFoldersOnTop: Bool = true
    @Published public var navigatorFilter: String = ""
    @Published private var _selectedFeature: String?
    @Published private var _workspaceFileManager: CEWorkspaceFileManager?

    private var workspaceState: [String: Any] {
        get {
            let key = self.fileURL?.absoluteString ?? ""
            return UserDefaults.standard.object(forKey: "workspaceState-\(key)") as? [String: Any] ?? [:]
        }
        set {
            let key = self.fileURL?.absoluteString ?? ""
            UserDefaults.standard.set(newValue, forKey: "workspaceState-\(key)")
        }
    }

    public var editorManager: EditorManager? = EditorManager()
    public var statusBarViewModel: StatusBarViewModel? = StatusBarViewModel()
    public var utilityAreaModel: UtilityAreaViewModel? = UtilityAreaViewModel()
    public var commandsPaletteState: CommandsPaletteState? = CommandsPaletteState()
    public var openQuicklyViewModel: OpenQuicklyViewModel?

    private var cancellables = Set<AnyCancellable>()
    
    public var fileURL: URL?

    public init() {
        // No initialization needed
    }
    
    public required init(configuration: ReadConfiguration) throws {
        // FileWrapper is not optional and has filename/directory properties
        let wrapper = configuration.file
        if wrapper.isDirectory,
           let filename = wrapper.preferredFilename {
            self.fileURL = URL(fileURLWithPath: filename)
        } else {
            throw CocoaError(.fileReadUnknown)
        }
        
        if let fileURL = self.fileURL {
            self._workspaceFileManager = .init(
                folderUrl: fileURL,
                ignoredFilesAndFolders: Set(ignoredFilesAndDirectory)
            )
        } else {
            self._workspaceFileManager = nil
        }
        
        self.editorManager = EditorManager()
        self.statusBarViewModel = StatusBarViewModel()
        self.utilityAreaModel = UtilityAreaViewModel()
        self.commandsPaletteState = CommandsPaletteState()
        self.openQuicklyViewModel = OpenQuicklyViewModel(workspace: self)
        
        // Restore state
        editorManager?.restoreFromState(self)
        utilityAreaModel?.restoreFromState(self)
    }
    
    public func snapshot(contentType: UTType) throws -> WorkspaceDocument {
        self
    }
    
    public func fileWrapper(snapshot: WorkspaceDocument, configuration: WriteConfiguration) throws -> FileWrapper {
        // Just create an empty directory wrapper since we don't need to save any file content
        let fileWrapper = FileWrapper(directoryWithFileWrappers: [:])
        return fileWrapper
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

        let _ = CodeEditWindowController(
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
        if let fileURL = fileURL {
            window.setAccessibilityDocument(fileURL.absoluteString)
        }
        window.makeKeyAndOrderFront(nil)
    }

    // MARK: Close Workspace

    public func close() {
        editorManager?.saveRestorationState(self)
        utilityAreaModel?.saveRestorationState(self)

        cancellables.forEach({ $0.cancel() })
        statusBarViewModel = nil
        utilityAreaModel = nil
        editorManager = nil
        _workspaceFileManager?.cleanUp()
        _workspaceFileManager = nil
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

extension WorkspaceDocument: WorkspaceDocumentProtocol, ObservableObject {
    public var selectedFeature: String? {
        get { _selectedFeature }
        set { _selectedFeature = newValue }
    }
    
    public var workspaceFileManager: CEWorkspaceFileManager? {
        get { _workspaceFileManager }
        set { _workspaceFileManager = newValue }
    }

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
