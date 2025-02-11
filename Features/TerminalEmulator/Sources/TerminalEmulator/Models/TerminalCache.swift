//
//  TerminalCache.swift
//  TerminalEmulator
//
//  Created by Claude on 2/11/25.
//

import Foundation
import SwiftUI
import AppKit

/// A singleton class that caches terminal views.
public final class TerminalCache {
    /// The shared instance of the terminal cache.
    public static let shared = TerminalCache()

    /// The cached terminal views.
    private var cache: [UUID: TerminalView] = [:]

    private init() {}

    /// Get a terminal view from the cache.
    /// - Parameter id: The ID of the terminal.
    /// - Returns: The cached terminal view, if it exists.
    public func getTerminalView(_ id: UUID) -> TerminalView? {
        return cache[id]
    }

    /// Add a terminal view to the cache.
    /// - Parameters:
    ///   - id: The ID of the terminal.
    ///   - view: The terminal view to cache.
    public func cacheTerminalView(_ id: UUID, view: TerminalView) {
        cache[id] = view
    }

    /// Remove a terminal view from the cache.
    /// - Parameter id: The ID of the terminal to remove.
    public func removeCachedView(_ id: UUID) {
        cache.removeValue(forKey: id)
    }

    /// Clear all cached terminal views.
    public func clearCache() {
        cache.removeAll()
    }
}

/// A view that represents a terminal.
public final class TerminalView: NSView {
    /// The process running in the terminal.
    public let process: TerminalProcess

    /// Initialize a new terminal view.
    /// - Parameters:
    ///   - shell: The shell to use. If nil, uses the default shell.
    ///   - workingDirectory: The directory to start in. If nil, uses the home directory.
    public init(shell: Shell? = nil, workingDirectory: URL? = nil) {
        self.process = TerminalProcess(
            shell: shell ?? .default,
            workingDirectory: workingDirectory ?? URL(filePath: NSHomeDirectory())
        )
        super.init(frame: NSRect(x: 0, y: 0, width: 100, height: 100))
        
        // Configure the view
        wantsLayer = true
        layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// A process running in a terminal.
public final class TerminalProcess: ObservableObject {
    /// The shell being used.
    public let shell: Shell

    /// The working directory.
    public let workingDirectory: URL

    /// The process ID of the shell.
    public private(set) var shellPid: pid_t = 0

    /// Initialize a new terminal process.
    /// - Parameters:
    ///   - shell: The shell to use.
    ///   - workingDirectory: The directory to start in.
    public init(shell: Shell, workingDirectory: URL) {
        self.shell = shell
        self.workingDirectory = workingDirectory
    }
}
