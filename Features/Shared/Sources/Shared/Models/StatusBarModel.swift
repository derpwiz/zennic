import SwiftUI

/// Helper struct used to store image dimensions
public struct ImageDimensions: Equatable {
    /// The width of the image in pixels
    public var width: Int
    
    /// The height of the image in pixels
    public var height: Int
    
    /// Creates new image dimensions
    /// - Parameters:
    ///   - width: The width in pixels
    ///   - height: The height in pixels
    public init(width: Int, height: Int) {
        self.width = width
        self.height = height
    }
}

/// A model representing the state of the status bar
public struct StatusBarModel: Equatable {
    /// The file size of the currently opened file
    public var fileSize: Int?
    
    /// The dimensions of the currently opened image
    public var dimensions: ImageDimensions?
    
    /// The current line number
    public var line: Int?
    
    /// The current column number
    public var column: Int?
    
    /// The current character offset
    public var characterOffset: Int?
    
    /// The number of selected characters
    public var selectedLength: Int?
    
    /// The number of selected lines
    public var selectedLines: Int?
    
    /// Creates a new status bar model
    /// - Parameters:
    ///   - fileSize: The file size in bytes
    ///   - dimensions: The image dimensions if applicable
    ///   - line: The current line number
    ///   - column: The current column number
    ///   - characterOffset: The current character offset
    ///   - selectedLength: The number of selected characters
    ///   - selectedLines: The number of selected lines
    public init(
        fileSize: Int? = nil,
        dimensions: ImageDimensions? = nil,
        line: Int? = nil,
        column: Int? = nil,
        characterOffset: Int? = nil,
        selectedLength: Int? = nil,
        selectedLines: Int? = nil
    ) {
        self.fileSize = fileSize
        self.dimensions = dimensions
        self.line = line
        self.column = column
        self.characterOffset = characterOffset
        self.selectedLength = selectedLength
        self.selectedLines = selectedLines
    }
}
