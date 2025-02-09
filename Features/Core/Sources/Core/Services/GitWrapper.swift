import Foundation
import Cgit2
import UI

/// A wrapper around libgit2 for Git operations
public class GitWrapper: Loggable {
    /// The path to the Git repository
    private let path: String
    
    /// The Git repository pointer
    private var repo: OpaquePointer?
    
    /// Creates a new Git wrapper
    /// - Parameter path: The path to the Git repository
    /// - Throws: GitError if initialization fails
    public init(path: String) throws {
        self.path = path
        
        // Initialize libgit2
        git_libgit2_init()
        
        // Open or create repository
        var repo: OpaquePointer?
        let result = git_repository_open(&repo, path)
        
        if result == GIT_ENOTFOUND.rawValue {
            // Repository doesn't exist, create it
            logger.info("Creating new Git repository at: \(path)")
            try createRepository()
        } else if result != 0 {
            // Other error
            let error = String(cString: git_error_last()?.pointee.message ?? "Unknown error")
            logger.error(GitError.initFailed)
            throw GitError.initFailed
        } else {
            logger.info("Opened existing Git repository at: \(path)")
            self.repo = repo
        }
    }
    
    /// Creates a new Git repository
    private func createRepository() throws {
        var repo: OpaquePointer?
        let result = git_repository_init(&repo, path, 0)
        
        if result != 0 {
            let error = String(cString: git_error_last()?.pointee.message ?? "Unknown error")
            logger.error(GitError.initFailed)
            throw GitError.initFailed
        }
        
        self.repo = repo
    }
    
    /// Gets the current branch name
    /// - Returns: The current branch name
    /// - Throws: GitError if the operation fails
    public func getCurrentBranch() throws -> String {
        guard let repo = repo else {
            logger.error(GitError.notInitialized)
            throw GitError.notInitialized
        }
        
        var head: OpaquePointer?
        let result = git_repository_head(&head, repo)
        
        if result != 0 {
            let error = String(cString: git_error_last()?.pointee.message ?? "Unknown error")
            logger.error(GitError.branchFailed)
            throw GitError.branchFailed
        }
        
        defer { git_reference_free(head) }
        
        let name = String(cString: git_reference_shorthand(head))
        logger.info("Current branch: \(name)")
        return name
    }
    
    /// Gets all local branches
    /// - Returns: Array of branch names
    /// - Throws: GitError if the operation fails
    public func getBranches() throws -> [String] {
        guard let repo = repo else {
            logger.error(GitError.notInitialized)
            throw GitError.notInitialized
        }
        
        var branches: OpaquePointer?
        guard git_branch_iterator_new(&branches, repo, GIT_BRANCH_LOCAL) == 0 else {
            logger.error(GitError.branchFailed)
            throw GitError.branchFailed
        }
        defer { git_branch_iterator_free(branches) }
        
        var results: [String] = []
        var ref: OpaquePointer?
        var type = git_branch_t(0)
        
        while git_branch_next(&ref, &type, branches) == 0 {
            defer { git_reference_free(ref) }
            
            guard let name = git_reference_shorthand(ref) else { continue }
            results.append(String(cString: name))
        }
        
        logger.info("Retrieved \(results.count) branches")
        return results
    }
    
    /// Creates a new branch
    /// - Parameter name: The branch name
    /// - Throws: GitError if the operation fails
    public func createBranch(name: String) throws {
        guard let repo = repo else {
            logger.error(GitError.notInitialized)
            throw GitError.notInitialized
        }
        
        var commit: OpaquePointer?
        var head = git_oid()
        guard git_reference_name_to_id(&head, repo, "HEAD") == 0,
              git_commit_lookup(&commit, repo, &head) == 0 else {
            logger.error(GitError.branchFailed)
            throw GitError.branchFailed
        }
        defer { git_commit_free(commit) }
        
        var branch: OpaquePointer?
        try name.withCString { name_str in
            guard git_branch_create(&branch, repo, name_str, commit, 0) == 0 else {
                logger.error(GitError.branchFailed)
                throw GitError.branchFailed
            }
        }
        if let branch = branch {
            git_reference_free(branch)
        }
        
        logger.info("Created branch: \(name)")
    }
    
    /// Checks out a branch
    /// - Parameter name: The branch name
    /// - Throws: GitError if the operation fails
    public func checkoutBranch(name: String) throws {
        guard let repo = repo else {
            logger.error(GitError.notInitialized)
            throw GitError.notInitialized
        }
        
        var reference: OpaquePointer?
        try name.withCString { name_str in
            guard git_branch_lookup(&reference, repo, name_str, GIT_BRANCH_LOCAL) == 0 else {
                logger.error(GitError.branchFailed)
                throw GitError.branchFailed
            }
        }
        defer { git_reference_free(reference) }
        
        var opts = git_checkout_options()
        git_checkout_init_options(&opts, UInt32(GIT_CHECKOUT_OPTIONS_VERSION))
        
        guard let ref_name = git_reference_name(reference),
              git_checkout_tree(repo, nil, &opts) == 0 else {
            logger.error(GitError.branchFailed)
            throw GitError.branchFailed
        }
        
        guard git_repository_set_head(repo, ref_name) == 0 else {
            logger.error(GitError.branchFailed)
            throw GitError.branchFailed
        }
        
        logger.info("Checked out branch: \(name)")
    }
    
    /// Gets the status of a file
    /// - Parameter file: The file path
    /// - Returns: The file status
    /// - Throws: GitError if the operation fails
    public func getStatus() throws -> [(String, String)] {
        guard let repo = repo else {
            logger.error(GitError.notInitialized)
            throw GitError.notInitialized
        }
        
        var statusList: OpaquePointer?
        var options = git_status_options()
        git_status_options_init(&options, UInt32(GIT_STATUS_OPTIONS_VERSION))
        
        let result = git_status_list_new(&statusList, repo, &options)
        
        if result != 0 {
            let error = String(cString: git_error_last()?.pointee.message ?? "Unknown error")
            logger.error(GitError.statusFailed)
            throw GitError.statusFailed
        }
        
        defer { git_status_list_free(statusList) }
        
        let count = git_status_list_entrycount(statusList)
        var statuses: [(String, String)] = []
        
        for i in 0..<count {
            guard let entry = git_status_byindex(statusList, i) else { continue }
            
            let status = entry.pointee.status
            let path = String(cString: entry.pointee.head_to_index?.pointee.new_file.path ?? entry.pointee.index_to_workdir?.pointee.new_file.path ?? "")
            
            if status.rawValue & GIT_STATUS_WT_NEW.rawValue != 0 {
                statuses.append(("Untracked", path))
            } else if status.rawValue & GIT_STATUS_WT_MODIFIED.rawValue != 0 {
                statuses.append(("Modified", path))
            }
        }
        
        logger.info("Retrieved status for \(statuses.count) files")
        return statuses
    }
    
    /// Adds a file to the index
    /// - Parameter file: The file path
    /// - Throws: GitError if the operation fails
    public func add(file: String) throws {
        guard let repo = repo else {
            logger.error(GitError.notInitialized)
            throw GitError.notInitialized
        }
        
        var index: OpaquePointer?
        var result = git_repository_index(&index, repo)
        
        if result != 0 {
            let error = String(cString: git_error_last()?.pointee.message ?? "Unknown error")
            logger.error(GitError.addFailed)
            throw GitError.addFailed
        }
        
        defer { git_index_free(index) }
        
        result = git_index_add_bypath(index, file)
        
        if result != 0 {
            let error = String(cString: git_error_last()?.pointee.message ?? "Unknown error")
            logger.error(GitError.addFailed)
            throw GitError.addFailed
        }
        
        result = git_index_write(index)
        
        if result != 0 {
            let error = String(cString: git_error_last()?.pointee.message ?? "Unknown error")
            logger.error(GitError.addFailed)
            throw GitError.addFailed
        }
        
        logger.info("Added file to index: \(file)")
    }
    
    /// Commits changes with a message
    /// - Parameter message: The commit message
    /// - Throws: GitError if the operation fails
    public func commit(message: String) throws {
        guard let repo = repo else {
            logger.error(GitError.notInitialized)
            throw GitError.notInitialized
        }
        
        var index: OpaquePointer?
        var result = git_repository_index(&index, repo)
        
        if result != 0 {
            let error = String(cString: git_error_last()?.pointee.message ?? "Unknown error")
            logger.error(GitError.commitFailed)
            throw GitError.commitFailed
        }
        
        defer { git_index_free(index) }
        
        var tree: OpaquePointer?
        var treeId = git_oid()
        
        result = git_index_write_tree(&treeId, index)
        
        if result != 0 {
            let error = String(cString: git_error_last()?.pointee.message ?? "Unknown error")
            logger.error(GitError.commitFailed)
            throw GitError.commitFailed
        }
        
        result = git_tree_lookup(&tree, repo, &treeId)
        
        if result != 0 {
            let error = String(cString: git_error_last()?.pointee.message ?? "Unknown error")
            logger.error(GitError.commitFailed)
            throw GitError.commitFailed
        }
        
        defer { git_tree_free(tree) }
        
        var signature: OpaquePointer?
        result = git_signature_default(&signature, repo)
        
        if result != 0 {
            let error = String(cString: git_error_last()?.pointee.message ?? "Unknown error")
            logger.error(GitError.commitFailed)
            throw GitError.commitFailed
        }
        
        defer { git_signature_free(signature) }
        
        var head: OpaquePointer?
        result = git_repository_head(&head, repo)
        
        if result != 0 {
            let error = String(cString: git_error_last()?.pointee.message ?? "Unknown error")
            logger.error(GitError.commitFailed)
            throw GitError.commitFailed
        }
        
        defer { git_reference_free(head) }
        
        var parent: OpaquePointer?
        result = git_commit_lookup(&parent, repo, git_reference_target(head))
        
        if result != 0 {
            let error = String(cString: git_error_last()?.pointee.message ?? "Unknown error")
            logger.error(GitError.commitFailed)
            throw GitError.commitFailed
        }
        
        defer { git_commit_free(parent) }
        
        var commitId = git_oid()
        let parents = [parent]
        
        result = git_commit_create(
            &commitId,
            repo,
            "HEAD",
            signature,
            signature,
            "UTF-8",
            message,
            tree,
            1,
            parents
        )
        
        if result != 0 {
            let error = String(cString: git_error_last()?.pointee.message ?? "Unknown error")
            logger.error(GitError.commitFailed)
            throw GitError.commitFailed
        }
        
        logger.info("Created commit: \(message)")
    }
    
    /// Gets the history of a file
    /// - Parameter file: The file path
    /// - Returns: Array of commits that modified the file
    /// - Throws: GitError if the operation fails
    public func getFileHistory(file: String) throws -> [GitCommit] {
        guard let repo = repo else {
            logger.error(GitError.notInitialized)
            throw GitError.notInitialized
        }
        
        var revwalk: OpaquePointer?
        var result = git_revwalk_new(&revwalk, repo)
        
        if result != 0 {
            let error = String(cString: git_error_last()?.pointee.message ?? "Unknown error")
            logger.error(GitError.historyFailed)
            throw GitError.historyFailed
        }
        
        defer { git_revwalk_free(revwalk) }
        
        git_revwalk_sorting(revwalk, GIT_SORT_TIME.rawValue | GIT_SORT_REVERSE.rawValue)
        git_revwalk_push_head(revwalk)
        
        var commits: [GitCommit] = []
        var oid = git_oid()
        
        while git_revwalk_next(&oid, revwalk) == 0 {
            var commit: OpaquePointer?
            result = git_commit_lookup(&commit, repo, &oid)
            
            if result != 0 {
                let error = String(cString: git_error_last()?.pointee.message ?? "Unknown error")
                logger.error(GitError.historyFailed)
                throw GitError.historyFailed
            }
            
            defer { git_commit_free(commit) }
            
            let message = String(cString: git_commit_message(commit))
            let author = String(cString: git_commit_author(commit).pointee.name)
            let timestamp = git_commit_time(commit)
            
            commits.append(GitCommit(
                message: message,
                author: author,
                timestamp: Date(timeIntervalSince1970: TimeInterval(timestamp))
            ))
        }
        
        logger.info("Retrieved \(commits.count) commits for file: \(file)")
        return commits
    }
    
    /// Gets the diff for a file
    /// - Parameter file: The file path
    /// - Returns: String containing the unified diff
    /// - Throws: GitError if the operation fails
    public func getDiff(file: String) throws -> String {
        guard let repo = repo else {
            logger.error(GitError.notInitialized)
            throw GitError.notInitialized
        }
        
        var diff: OpaquePointer?
        var options = git_diff_options()
        git_diff_options_init(&options, UInt32(GIT_DIFF_OPTIONS_VERSION))
        
        var result = git_diff_index_to_workdir(&diff, repo, nil, &options)
        
        if result != 0 {
            let error = String(cString: git_error_last()?.pointee.message ?? "Unknown error")
            logger.error(GitError.diffFailed)
            throw GitError.diffFailed
        }
        
        defer { git_diff_free(diff) }
        
        var buffer = git_buf()
        result = git_diff_to_buf(&buffer, diff, GIT_DIFF_FORMAT_PATCH.rawValue)
        
        if result != 0 {
            let error = String(cString: git_error_last()?.pointee.message ?? "Unknown error")
            logger.error(GitError.diffFailed)
            throw GitError.diffFailed
        }
        
        defer { git_buf_dispose(&buffer) }
        
        let diffText = String(cString: buffer.ptr)
        logger.info("Retrieved diff for file: \(file)")
        return diffText
    }
    
    deinit {
        if let repo = repo {
            git_repository_free(repo)
        }
        git_libgit2_shutdown()
    }
}

/// Git commit information
public struct GitCommit {
    /// The commit message
    public let message: String
    
    /// The commit author
    public let author: String
    
    /// The commit timestamp
    public let timestamp: Date
}

/// Git errors
public enum GitError: Error {
    case initFailed
    case notInitialized
    case branchFailed
    case statusFailed
    case addFailed
    case commitFailed
    case historyFailed
    case diffFailed
}
