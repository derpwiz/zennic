//
//  Shell.swift
//  TerminalEmulator
//
//  Created by Claude on 2/11/25.
//

import Foundation

/// Represents a shell that can be used in a terminal.
public enum Shell: String, CaseIterable {
    case bash = "/bin/bash"
    case zsh = "/bin/zsh"
    case fish = "/usr/local/bin/fish"

    /// The default shell for the current user.
    public static var `default`: Shell {
        let shell = ProcessInfo.processInfo.environment["SHELL"] ?? "/bin/zsh"
        return Shell(rawValue: shell) ?? .zsh
    }

    /// The arguments to pass to the shell when launching.
    public var arguments: [String] {
        switch self {
        case .bash:
            return ["--login"]
        case .zsh:
            return ["--login"]
        case .fish:
            return ["--login", "--interactive"]
        }
    }

    /// The environment variables to set for the shell.
    public var environment: [String: String] {
        var env = ProcessInfo.processInfo.environment
        env["TERM"] = "xterm-256color"
        env["COLORTERM"] = "truecolor"
        return env
    }

    /// Check if a shell is available on the system.
    public var isAvailable: Bool {
        FileManager.default.fileExists(atPath: rawValue)
    }
}
