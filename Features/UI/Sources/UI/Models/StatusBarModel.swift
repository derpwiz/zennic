import SwiftUI

/// Represents dimensions for status bar icons.
public struct StatusBarIconDimensions {
    public static let width: CGFloat = 24
    public static let height: CGFloat = 24
    public static let spacing: CGFloat = 8
}

/// Represents the line ending type for a file.
public enum LineEnding: String, CaseIterable {
    case lf = "LF"
    case crlf = "CRLF"
    case cr = "CR"
    
    public var description: String {
        switch self {
        case .lf: return "Unix (LF)"
        case .crlf: return "Windows (CRLF)"
        case .cr: return "Classic Mac (CR)"
        }
    }
    
    public var icon: String {
        switch self {
        case .lf: return "arrow.turn.down.left"
        case .crlf: return "arrow.turn.down.left"
        case .cr: return "arrow.turn.down.left"
        }
    }
}

/// Represents the indentation type for a file.
public enum IndentationType: String, CaseIterable {
    case spaces = "Spaces"
    case tabs = "Tabs"
    
    public var description: String {
        rawValue
    }
    
    public var icon: String {
        switch self {
        case .spaces: return "arrow.right.to.line"
        case .tabs: return "arrow.right.to.line.compact"
        }
    }
}

/// Represents the encoding type for a file.
public enum FileEncoding: String, CaseIterable {
    case utf8 = "UTF-8"
    case utf16 = "UTF-16"
    case ascii = "ASCII"
    
    public var description: String {
        rawValue
    }
    
    public var icon: String {
        "textformat"
    }
}
