import Foundation
import UI

/// A service for managing Git operations
public class GitService: Loggable {
    /// The Git wrapper
    private let gitWrapper: GitWrapper
    
    /// Creates a new Git service
    /// - Parameter path: The path to the Git repository
    /// - Throws: GitError if initialization fails
    public init(path: String) throws {
        logger.info("Initializing Git service for: \(path)")
        self.gitWrapper = try GitWrapper(path: path)
    }
    
    /// Gets the current branch name
    /// - Returns: The current branch name
    /// - Throws: GitError if the operation fails
    public func getCurrentBranch() throws -> String {
        let branch = try gitWrapper.getCurrentBranch()
        logger.info("Current branch: \(branch)")
        return branch
    }
    
    /// Gets the status of files in the repository
    /// - Returns: Array of tuples containing status and file path
    /// - Throws: GitError if the operation fails
    public func getStatus() throws -> [(String, String)] {
        let status = try gitWrapper.getStatus()
        logger.info("Retrieved status for \(status.count) files")
        
        // Log individual file statuses
        status.forEach { status, path in
            logger.info("File status: \(status) - \(path)")
        }
        
        return status
    }
    
    /// Adds a file to the index
    /// - Parameter file: The file path
    /// - Throws: GitError if the operation fails
    public func add(file: String) throws {
        logger.info("Adding file to index: \(file)")
        try gitWrapper.add(file: file)
    }
    
    /// Commits changes with a message
    /// - Parameter message: The commit message
    /// - Throws: GitError if the operation fails
    public func commit(message: String) throws {
        logger.info("Creating commit: \(message)")
        try gitWrapper.commit(message: message)
    }
    
    /// Gets the history of a file
    /// - Parameter file: The file path
    /// - Returns: Array of commits that modified the file
    /// - Throws: GitError if the operation fails
    public func getHistory(for file: String) throws -> [GitCommit] {
        logger.info("Retrieving history for: \(file)")
        let history = try gitWrapper.getFileHistory(file: file)
        
        // Log commit details
        history.forEach { commit in
            logger.info("Commit: \(commit.message) by \(commit.author) at \(commit.timestamp)")
        }
        
        return history
    }
    
    /// Gets the diff for a file
    /// - Parameter file: The file path
    /// - Returns: String containing the unified diff
    /// - Throws: GitError if the operation fails
    public func getDiff(for file: String) throws -> String {
        logger.info("Retrieving diff for: \(file)")
        let diff = try gitWrapper.getDiff(file: file)
        
        // Log diff size
        logger.info("Diff size: \(diff.count) characters")
        
        return diff
    }
    
    /// Stages and commits a file with a message
    /// - Parameters:
    ///   - file: The file path
    ///   - message: The commit message
    /// - Throws: GitError if the operation fails
    public func stageAndCommit(file: String, message: String) throws {
        logger.info("Staging and committing: \(file)")
        try add(file: file)
        try commit(message: message)
        logger.info("Successfully staged and committed: \(file)")
    }
    
    /// Gets the status of a specific file
    /// - Parameter file: The file path
    /// - Returns: The file status or nil if not found
    /// - Throws: GitError if the operation fails
    public func getFileStatus(for file: String) throws -> String? {
        logger.info("Getting status for: \(file)")
        let status = try getStatus()
        let fileStatus = status.first { $0.1 == file }?.0
        
        if let status = fileStatus {
            logger.info("File status: \(status) - \(file)")
        } else {
            logger.info("No status found for: \(file)")
        }
        
        return fileStatus
    }
    
    /// Checks if a file has uncommitted changes
    /// - Parameter file: The file path
    /// - Returns: True if the file has changes
    /// - Throws: GitError if the operation fails
    public func hasChanges(file: String) throws -> Bool {
        logger.info("Checking for changes in: \(file)")
        let status = try getFileStatus(for: file)
        let hasChanges = status != nil
        
        if hasChanges {
            logger.info("Found changes in: \(file)")
        } else {
            logger.info("No changes found in: \(file)")
        }
        
        return hasChanges
    }
}
