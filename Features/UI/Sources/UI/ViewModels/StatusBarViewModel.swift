import SwiftUI
import Combine

/// A view model that manages the state of the status bar
public final class StatusBarViewModel: ObservableObject {
    /// The current state of the status bar
    @Published public var model: StatusBarModel
    
    /// The font style of items shown in the status bar
    public let statusBarFont = Font.system(size: 11, weight: .medium)
    
    /// The color of the text shown in the status bar
    public let foregroundStyle = Color.secondary
    
    /// Creates a new status bar view model
    /// - Parameter model: The initial state of the status bar
    public init(model: StatusBarModel = .init()) {
        self.model = model
    }
    
    /// Updates the file information
    /// - Parameters:
    ///   - fileSize: The file size in bytes
    ///   - dimensions: The image dimensions if applicable
    public func updateFileInfo(fileSize: Int?, dimensions: ImageDimensions?) {
        model.fileSize = fileSize
        model.dimensions = dimensions
    }
    
    /// Updates the cursor position information
    /// - Parameters:
    ///   - line: The current line number
    ///   - column: The current column number
    ///   - characterOffset: The current character offset
    public func updateCursorPosition(
        line: Int?,
        column: Int?,
        characterOffset: Int?
    ) {
        model.line = line
        model.column = column
        model.characterOffset = characterOffset
    }
    
    /// Updates the selection information
    /// - Parameters:
    ///   - length: The number of selected characters
    ///   - lines: The number of selected lines
    public func updateSelection(length: Int?, lines: Int?) {
        model.selectedLength = length
        model.selectedLines = lines
    }
    
    /// Formats the cursor position label based on the current state
    /// - Parameter showCharacterOffset: Whether to show character offset instead of line/column
    /// - Returns: A string describing the cursor position or selection
    public func formatCursorPosition(showCharacterOffset: Bool = false) -> String {
        // If there's a selection spanning multiple lines
        if let selectedLines = model.selectedLines, selectedLines > 1 {
            return "\(selectedLines) lines"
        }
        
        // If there's a selection on a single line
        if let selectedLength = model.selectedLength, selectedLength > 0 {
            if showCharacterOffset {
                return "Char: \(model.characterOffset ?? 0) Len: \(selectedLength)"
            }
            return "\(selectedLength) characters"
        }
        
        // If it's just a cursor position
        if showCharacterOffset {
            return "Char: \(model.characterOffset ?? 0) Len: 0"
        }
        
        if let line = model.line, let column = model.column {
            return "Line: \(line)  Col: \(column)"
        }
        
        return ""
    }
}
