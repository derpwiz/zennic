//
//  Editor.swift
//  Editor
//
//  Created by Claude on 2/11/25.
//

import Foundation
import SwiftUI
import AppKit
import DocumentsInterface

/// An editor instance that manages a set of open tabs.
public final class Editor: ObservableObject, Identifiable {
    public typealias Tab = EditorInstance

    /// Set of open tabs.
    @Published public var tabs: [Tab] = [] {
        didSet {
            let change = Set(tabs).symmetricDifference(Set(oldValue))

            if tabs.count > oldValue.count {
                // Amount of tabs grew, so set the first new as selected.
                setSelectedTab(change.first?.file)
            } else {
                // Selected file was removed
                if let selectedTab, change.contains(selectedTab) {
                    if let oldIndex = oldValue.firstIndex(of: selectedTab), oldIndex - 1 < tabs.count, !tabs.isEmpty {
                        setSelectedTab(tabs[max(0, oldIndex-1)].file)
                    } else {
                        setSelectedTab(nil)
                    }
                }
            }
        }
    }

    /// Currently selected tab.
    @Published public private(set) var selectedTab: Tab?

    /// Temporary tab (e.g., for quick look)
    @Published public var temporaryTab: Tab?

    public var id = UUID()

    public weak var parent: SplitViewData?

    public init() {
        self.tabs = []
        self.temporaryTab = nil
        self.parent = nil
    }

    public init(
        files: [CEWorkspaceFile] = [],
        selectedTab: Tab? = nil,
        temporaryTab: Tab? = nil,
        parent: SplitViewData? = nil
    ) {
        self.tabs = []
        self.parent = parent
        files.forEach { openTab(file: $0, at: nil) }
        self.selectedTab = selectedTab ?? (files.isEmpty ? nil : Tab(file: files.first!))
        self.temporaryTab = temporaryTab
    }

    public init(
        files: [Tab] = [],
        selectedTab: Tab? = nil,
        temporaryTab: Tab? = nil,
        parent: SplitViewData? = nil
    ) {
        self.tabs = []
        self.parent = parent
        files.forEach { openTab(file: $0.file, at: nil) }
        self.selectedTab = selectedTab ?? tabs.first
        self.temporaryTab = temporaryTab
    }

    /// Closes the editor.
    public func close() {
        parent?.closeEditor(with: id)
    }

    /// Gets the editor layout.
    public func getEditorLayout() -> EditorLayout? {
        return parent?.getEditorLayout(with: id)
    }

    /// Set the selected tab. Loads the file's contents if it hasn't already been opened.
    /// - Parameter file: The file to set as the selected tab.
    public func setSelectedTab(_ file: CEWorkspaceFile?) {
        guard let file else {
            selectedTab = nil
            return
        }
        guard let tab = self.tabs.first(where: { $0.file == file }) else {
            return
        }
        self.selectedTab = tab
        if tab.file.fileDocument == nil {
            do { // Ignore this error for simpler API usage.
                try openFile(item: tab)
            } catch {
                print(error)
            }
        }
    }

    /// Closes a tab in the editor.
    /// This will also write any changes to the file on disk.
    /// - Parameter file: The tab to close
    public func closeTab(file: CEWorkspaceFile) {
        guard canCloseTab(file: file) else { return }

        if temporaryTab?.file == file {
            temporaryTab = nil
        }
        removeTab(file)
        // Reset change count to 0
        file.fileDocument?.updateChangeCount(.changeCleared)
        if let codeFile = file.fileDocument {
            codeFile.close()
        }
        // remove file from memory
        file.fileDocument = nil
    }

    /// Closes the currently opened tab in the tab group.
    public func closeSelectedTab() {
        guard let file = selectedTab?.file else {
            return
        }

        closeTab(file: file)
    }

    /// Opens a tab in the editor.
    /// If a tab for the item already exists, it is used instead.
    /// - Parameters:
    ///   - file: the file to open.
    ///   - temporary: indicates whether the tab should be opened as a temporary tab or a permanent tab.
    public func openTabAsTemporary(file: CEWorkspaceFile, temporary: Bool = false) {
        let item = EditorInstance(file: file)
        // Item is already opened in a tab.
        guard !tabs.contains(item) || !temporary else {
            selectedTab = item
            return
        }

        switch (temporaryTab, temporary) {
        case (.some(let tab), true):
            if let index = tabs.firstIndex(of: tab) {
                tabs.remove(at: index)
                tabs.insert(item, at: index)
                self.selectedTab = item
                temporaryTab = item
            }

        case (.some(let tab), false) where tab == item:
            temporaryTab = nil

        case (.none, true):
            openTab(file: item.file, at: nil)
            temporaryTab = item

        case (.none, false):
            openTab(file: item.file, at: nil)

        default:
            break
        }
    }

    /// Opens a tab in the editor.
    /// - Parameters:
    ///   - file: The tab to open.
    ///   - index: Index where the tab needs to be added. If nil, it is added to the back.
    public func openTab(file: CEWorkspaceFile, at index: Int? = nil) {
        let item = Tab(file: file)
        if let index {
            tabs.insert(item, at: index)
        } else {
            if let selectedTab, let currentIndex = tabs.firstIndex(of: selectedTab) {
                tabs.insert(item, at: tabs.index(after: currentIndex))
            } else {
                tabs.append(item)
            }
        }

        selectedTab = item
        do {
            try openFile(item: item)
        } catch {
            print(error)
        }
    }

    private func openFile(item: Tab) throws {
        guard item.file.fileDocument == nil else {
            return
        }

        let contentType = item.file.resolvedURL.contentType
        let codeFile = try CodeFileDocument(
            for: item.file.url,
            withContentsOf: item.file.resolvedURL,
            ofType: contentType?.identifier ?? ""
        )
        item.file.fileDocument = codeFile
        CodeEditDocumentController.shared.addDocument(codeFile)
    }

    /// Check if tab can be closed
    ///
    /// If document edited it will show dialog where user can save document before closing or cancel.
    private func canCloseTab(file: CEWorkspaceFile) -> Bool {
        guard let codeFile = file.fileDocument else { return true }

        if codeFile.isDocumentEdited {
            let shouldClose = UnsafeMutablePointer<Bool>.allocate(capacity: 1)
            shouldClose.initialize(to: true)
            defer {
                _ = shouldClose.move()
                shouldClose.deallocate()
            }
            codeFile.canClose(
                withDelegate: self,
                shouldClose: #selector(document(_:shouldClose:contextInfo:)),
                contextInfo: shouldClose
            )

            return shouldClose.pointee
        }

        return true
    }

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

    /// Remove the given file from tabs.
    /// - Parameter file: The file to remove.
    public func removeTab(_ file: CEWorkspaceFile) {
        tabs.removeAll(where: { tab in tab.file == file })
        if temporaryTab?.file == file {
            temporaryTab = nil
        }
    }
}

extension Editor: Equatable, Hashable {
    public static func == (lhs: Editor, rhs: Editor) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
