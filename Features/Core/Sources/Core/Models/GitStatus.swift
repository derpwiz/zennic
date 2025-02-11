import Foundation

/// Represents the status of a file in a Git repository
public struct GitStatus {
    /// The path to the file
    public let file: String
    
    /// The status of the file (e.g., modified, added, deleted)
    public let state: String
    
    /// A description of the file's status
    public let description: String
    
    /// Creates a new Git status
    /// - Parameters:
    ///   - file: The path to the file
    ///   - state: The status of the file
    ///   - description: A description of the file's status
    public init(file: String, state: String, description: String) {
        self.file = file
        self.state = state
        self.description = description
    }
}
