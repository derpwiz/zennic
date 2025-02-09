import Foundation

/// Represents the status of a file in a Git repository
public struct GitStatus {
    /// The path to the file
    public let path: String
    
    /// The status of the file (e.g., modified, added, deleted)
    public let status: String
    
    /// Creates a new Git status
    /// - Parameters:
    ///   - path: The path to the file
    ///   - status: The status of the file
    public init(path: String, status: String) {
        self.path = path
        self.status = status
    }
}
