//
//  UtilityAreaTerminal.swift
//  UtilityArea
//
//  Created by Claude on 2/11/25.
//

import Foundation
import TerminalEmulator

/// Represents a terminal instance in the utility area.
public final class UtilityAreaTerminal: Identifiable, Hashable {
    /// The unique identifier for this terminal.
    public let id: UUID

    /// The URL where the terminal is running.
    public let url: URL

    /// The title of the terminal.
    public var title: String {
        didSet {
            if !customTitle {
                terminalTitle = title
            }
        }
    }

    /// The title displayed in the terminal.
    public var terminalTitle: String

    /// Whether the title has been customized by the user.
    public var customTitle: Bool = false

    /// The shell to use for this terminal.
    public let shell: Shell?

    public init(
        id: UUID = UUID(),
        url: URL,
        title: String,
        shell: Shell? = nil
    ) {
        self.id = id
        self.url = url
        self.title = title
        self.terminalTitle = title
        self.shell = shell
    }

    public static func == (lhs: UtilityAreaTerminal, rhs: UtilityAreaTerminal) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
