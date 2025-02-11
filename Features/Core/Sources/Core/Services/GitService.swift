import Foundation
import Shared

/// A service for managing Git operations
public class GitService: Loggable {
    /// The Git wrapper
    private let gitWrapper: GitWrapper
    
    /// The path to the Git repository
    private let path: String
    
    /// Creates a new Git service
    /// - Parameter path: The path to the Git repository
    /// - Throws: GitError if initialization fails
    public init(path: String) throws {
        self.path = path
        self.gitWrapper = try GitWrapper(path: path)
        logger.info("Initializing Git service for: \(path)")
    }
    
    /// Gets all branches in the repository
    /// - Returns: Array of branch names
    /// - Throws: GitError if the operation fails
    public func getBranches() throws -> [String] {
        logger.info("Getting branches")
        let branches = try gitWrapper.getBranches()
        logger.info("Found \(branches.count) branches")
        return branches
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
    /// - Returns: Array of GitStatus objects
    /// - Throws: GitError if the operation fails
    public func getStatus() throws -> [GitStatus] {
        let status = try gitWrapper.getStatus()
        logger.info("Retrieved status for \(status.count) files")
        
        return status.map { status, path in
            let description: String
            switch status {
            case "Modified":
                description = "File has been modified"
            case "Untracked":
                description = "New file"
            case "Added":
                description = "Added to index"
            case "Deleted":
                description = "File has been deleted"
            case "Renamed":
                description = "File has been renamed"
            case "Copied":
                description = "File has been copied"
            case "Updated":
                description = "File has been updated"
            default:
                description = "Unknown status"
            }
            
            logger.info("File status: \(status) - \(path)")
            return GitStatus(file: path, state: status, description: description)
        }
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
    
    /// Checks out a branch
    /// - Parameter name: The branch name
    /// - Throws: GitError if the operation fails
    public func checkoutBranch(name: String) throws {
        logger.info("Checking out branch: \(name)")
        try gitWrapper.checkoutBranch(name: name)
        logger.info("Successfully checked out branch: \(name)")
    }

    /// Creates a new branch
    /// - Parameter name: The branch name
    /// - Throws: GitError if the operation fails
    public func createBranch(name: String) throws {
        logger.info("Creating branch: \(name)")
        try gitWrapper.createBranch(name: name)
        logger.info("Successfully created branch: \(name)")
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
    /// - Returns: The GitStatus object or nil if not found
    /// - Throws: GitError if the operation fails
    public func getFileStatus(for file: String) throws -> GitStatus? {
        logger.info("Getting status for: \(file)")
        let status = try getStatus()
        let fileStatus = status.first { $0.file == file }
        
        if let status = fileStatus {
            logger.info("File status: \(status.state) - \(file)")
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
    
    /// Lists all files in the repository
    /// - Returns: Array of file paths
    /// - Throws: GitError if the operation fails
    public func listFiles() throws -> [String] {
        logger.info("Listing files in repository")
        let fileManager = FileManager.default
        let contents = try fileManager.contentsOfDirectory(atPath: path)
        logger.info("Found \(contents.count) files")
        return contents
    }
    
    /// Creates a new file with content
    /// - Parameters:
    ///   - name: The file name
    ///   - content: The file content
    /// - Throws: GitError if the operation fails
    public func createFile(name: String, content: String) throws {
        logger.info("Creating file: \(name)")
        let filePath = (path as NSString).appendingPathComponent(name)
        try content.write(toFile: filePath, atomically: true, encoding: .utf8)
        try add(file: name)
        try commit(message: "Create \(name)")
        logger.info("Created and committed file: \(name)")
    }
    
    /// Deletes a file
    /// - Parameter name: The file name
    /// - Throws: GitError if the operation fails
    public func deleteFile(name: String) throws {
        logger.info("Deleting file: \(name)")
        let filePath = (path as NSString).appendingPathComponent(name)
        try FileManager.default.removeItem(atPath: filePath)
        try stageAndCommit(file: name, message: "Delete \(name)")
        logger.info("Deleted and committed file: \(name)")
    }
}
