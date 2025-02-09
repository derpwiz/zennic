import SwiftUI

/// Manages the state of the status bar.
public final class StatusBarViewModel: ObservableObject {
    /// The current line ending type.
    @Published public var lineEnding: LineEnding = .lf
    
    /// The current indentation type.
    @Published public var indentationType: IndentationType = .spaces
    
    /// The current file encoding.
    @Published public var fileEncoding: FileEncoding = .utf8
    
    /// The current cursor position.
    @Published public var cursorPosition: (line: Int, column: Int) = (1, 1)
    
    /// Whether the file has unsaved changes.
    @Published public var hasUnsavedChanges: Bool = false
    
    /// The current file path.
    @Published public var filePath: String = ""
    
    /// The current file name.
    public var fileName: String {
        (filePath as NSString).lastPathComponent
    }
    
    /// Creates a new status bar view model.
    public init() {}
    
    /// Updates the cursor position.
    /// - Parameters:
    ///   - line: The line number.
    ///   - column: The column number.
    public func updateCursorPosition(line: Int, column: Int) {
        cursorPosition = (line, column)
    }
    
    /// Updates the file path.
    /// - Parameter path: The new file path.
    public func updateFilePath(_ path: String) {
        filePath = path
    }
    
    /// Updates whether the file has unsaved changes.
    /// - Parameter hasChanges: Whether the file has unsaved changes.
    public func updateUnsavedChanges(_ hasChanges: Bool) {
        hasUnsavedChanges = hasChanges
    }
}

/// A key for accessing the status bar view model in the environment.
private struct StatusBarViewModelKey: EnvironmentKey {
    static let defaultValue = StatusBarViewModel()
}

extension EnvironmentValues {
    /// The status bar view model.
    public var statusBarViewModel: StatusBarViewModel {
        get { self[StatusBarViewModelKey.self] }
        set { self[StatusBarViewModelKey.self] = newValue }
    }
}
