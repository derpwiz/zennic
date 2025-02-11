//
//  CEWorkspaceFile.swift
//  zennic
//
//  Created by Claude on 2/11/25.
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers
import Combine

/// An object containing all necessary information and actions for a specific file in the workspace
final class CEWorkspaceFile: Codable, Comparable, Hashable, Identifiable {
    /// The id of the file
    var id: String

    /// Returns the file name (e.g.: `Package.swift`)
    var name: String { url.lastPathComponent.trimmingCharacters(in: .whitespacesAndNewlines) }

    /// Returns the extension of the file or an empty string if no extension is present.
    var type: FileIcon.FileType {
        let filename = url.lastPathComponent

        /// First, check if there is a valid file extension.
        if let type = FileIcon.FileType(rawValue: filename) {
            return type
        } else {
            /// If there's not, verifies every extension for a valid type.
            let extensions = filename.dropFirst().components(separatedBy: ".").reversed()

            return extensions
                .compactMap { FileIcon.FileType(rawValue: $0) }
                .first
            /// Returns .txt for invalid type.
            ?? .txt
        }
    }

    /// Returns the URL of the file
    let url: URL

    /// Returns the resolved symlink url of this object.
    lazy var resolvedURL: URL = {
        url.isSymbolicLink ? url.resolvingSymlinksInPath() : url
    }()

    /// Return the icon of the file as `Image`
    var icon: Image {
        if let customImage = NSImage.symbol(named: systemImage) {
            return Image(nsImage: customImage)
        } else {
            return Image(systemName: systemImage)
        }
    }

    /// Return the icon of the file as `NSImage`
    var nsIcon: NSImage {
        if let customImage = NSImage.symbol(named: systemImage) {
            return customImage
        } else {
            return NSImage(systemSymbolName: systemImage, accessibilityDescription: systemImage)
                ?? NSImage(systemSymbolName: "doc", accessibilityDescription: "doc")!
        }
    }

    /// Returns a parent file.
    weak var parent: CEWorkspaceFile?

    /// Returns a boolean that is true if the resource represented by this object is a directory.
    lazy var isFolder: Bool = {
        (try? resolvedURL.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
    }()

    /// Returns a boolean that is true if the contents of the directory at this path are empty
    var isEmptyFolder: Bool {
        (try? CEWorkspaceFile.fileManager.contentsOfDirectory(
            at: resolvedURL,
            includingPropertiesForKeys: nil,
            options: .skipsSubdirectoryDescendants
        ).isEmpty) ?? true
    }

    /// Returns a boolean that is true if the file item is the root folder of the workspace.
    var isRoot: Bool { parent == nil }

    /// Returns a boolean that is true if the file item actually exists in the file system
    var doesExist: Bool { CEWorkspaceFile.fileManager.fileExists(atPath: self.url.path) }

    /// Returns a string describing a SFSymbol for the current file
    var systemImage: String {
        if isFolder {
            // item is a folder
            return folderIcon()
        } else {
            // item is a file
            return FileIcon.fileIcon(fileType: type)
        }
    }

    /// Return the file's UTType
    var contentType: UTType? {
        try? url.resourceValues(forKeys: [.contentTypeKey]).contentType
    }

    /// Returns a `Color` for a specific `fileType`
    var iconColor: Color {
        FileIcon.iconColor(fileType: type)
    }

    init(
        id: String,
        url: URL
    ) {
        self.id = id
        self.url = url
    }

    convenience init(url: URL) {
        self.init(
            id: url.relativePath,
            url: url
        )
    }

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case url
    }

    required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(String.self, forKey: .id)
        url = try values.decode(URL.self, forKey: .url)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(url, forKey: .url)
    }

    /// Returns a string describing a SFSymbol for folders
    private func folderIcon() -> String {
        if self.parent == nil {
            return "folder.fill.badge.gearshape"
        }
        return isEmptyFolder ? "folder" : "folder.fill"
    }

    /// Returns the file name with optional extension (e.g.: `Package.swift`)
    func fileName(typeHidden: Bool = false) -> String {
        typeHidden ? url.deletingPathExtension()
            .lastPathComponent
            .trimmingCharacters(in: .whitespacesAndNewlines) : name
    }

    // MARK: Statics
    /// The default `FileManager` instance
    static let fileManager = FileManager.default

    // MARK: Intents
    /// Allows the user to view the file or folder in the finder application
    func showInFinder() {
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }

    /// Allows the user to launch the file or folder as it would be in finder
    func openWithExternalEditor() {
        NSWorkspace.shared.open(url)
    }

    /// Nearest folder refers to the parent directory if this is a non-folder item, or itself if the item is a folder.
    var nearestFolder: URL {
        (self.isFolder ?
                    self.url :
                    self.url.deletingLastPathComponent())
    }

    // MARK: Comparable

    static func == (lhs: CEWorkspaceFile, rhs: CEWorkspaceFile) -> Bool {
        lhs.id == rhs.id
    }

    static func < (lhs: CEWorkspaceFile, rhs: CEWorkspaceFile) -> Bool {
        lhs.url.lastPathComponent < rhs.url.lastPathComponent
    }

    // MARK: Hashable

    func hash(into hasher: inout Hasher) {
        hasher.combine(url)
        hasher.combine(id)
    }
}

extension URL {
    var isSymbolicLink: Bool {
        (try? resourceValues(forKeys: [.isSymbolicLinkKey]).isSymbolicLink) ?? false
    }
}
