import Foundation
import Cgit2

public class GitWrapper {
    private var repo: OpaquePointer?
    private let path: String
    
    public init(path: String) throws {
        self.path = path
        var repo: OpaquePointer?
        
        // Try to open existing repository
        if git_repository_open(&repo, path) == 0 {
            self.repo = repo
            return
        }
        
        // If repository doesn't exist, initialize a new one
        if git_repository_init(&repo, path, 0) != 0 {
            throw GitError.initFailed
        }
        
        self.repo = repo
    }
    
    deinit {
        if let repo = repo {
            git_repository_free(repo)
        }
    }
    
    public func add(file: String) throws {
        guard let repo = repo else { throw GitError.addFailed }
        
        var index: OpaquePointer?
        guard git_repository_index(&index, repo) == 0 else {
            throw GitError.addFailed
        }
        defer { git_index_free(index) }
        
        guard git_index_add_bypath(index, file) == 0 else {
            throw GitError.addFailed
        }
        
        guard git_index_write(index) == 0 else {
            throw GitError.addFailed
        }
    }
    
    public func commit(message: String) throws {
        guard let repo = repo else { throw GitError.commitFailed }
        
        var index: OpaquePointer?
        guard git_repository_index(&index, repo) == 0 else {
            throw GitError.commitFailed
        }
        defer { git_index_free(index) }
        
        var tree_id = git_oid()
        guard git_index_write_tree(&tree_id, index) == 0 else {
            throw GitError.commitFailed
        }
        
        var tree: OpaquePointer?
        guard git_tree_lookup(&tree, repo, &tree_id) == 0 else {
            throw GitError.commitFailed
        }
        defer { git_tree_free(tree) }
        
        var parent_commit: OpaquePointer?
        var head = git_oid()
        if git_reference_name_to_id(&head, repo, "HEAD") == 0 {
            guard git_commit_lookup(&parent_commit, repo, &head) == 0 else {
                throw GitError.commitFailed
            }
        }
        defer {
            if let parent = parent_commit {
                git_commit_free(parent)
            }
        }
        
        var signature: UnsafeMutablePointer<git_signature>?
        guard git_signature_default(&signature, repo) == 0,
              let signature = signature else {
            throw GitError.commitFailed
        }
        defer { git_signature_free(signature) }
        
        var commit_id = git_oid()
        let parents = parent_commit != nil ? 1 : 0
        try withUnsafeMutablePointer(to: &commit_id) { commit_id_ptr in
            try "HEAD".withCString { head_ref in
                try message.withCString { message_str in
                    guard git_commit_create(
                        commit_id_ptr,
                        repo,
                        head_ref,
                        UnsafePointer(signature),
                        UnsafePointer(signature),
                        "UTF-8",
                        message_str,
                        tree,
                        parents,
                        parent_commit
                    ) == 0 else {
                        throw GitError.commitFailed
                    }
                }
            }
        }
    }
    
    public func getStatus() throws -> [(String, String)] {
        guard let repo = repo else { throw GitError.statusFailed }
        
        var options = git_status_options()
        git_status_init_options(&options, UInt32(GIT_STATUS_OPTIONS_VERSION))
        options.show = GIT_STATUS_SHOW_INDEX_AND_WORKDIR
        options.flags = GIT_STATUS_OPT_INCLUDE_UNTRACKED.rawValue |
                       GIT_STATUS_OPT_RENAMES_HEAD_TO_INDEX.rawValue |
                       GIT_STATUS_OPT_SORT_CASE_SENSITIVELY.rawValue
        
        var statusList: OpaquePointer?
        guard git_status_list_new(&statusList, repo, &options) == 0 else {
            throw GitError.statusFailed
        }
        defer { git_status_list_free(statusList) }
        
        let count = git_status_list_entrycount(statusList)
        var results: [(String, String)] = []
        
        for i in 0..<count {
            guard let entry = git_status_byindex(statusList, i) else { continue }
            
            let status = entry.pointee.status
            let path: String
            
            if status.rawValue & GIT_STATUS_INDEX_NEW.rawValue != 0 ||
               status.rawValue & GIT_STATUS_INDEX_MODIFIED.rawValue != 0 ||
               status.rawValue & GIT_STATUS_INDEX_DELETED.rawValue != 0 {
                path = String(cString: entry.pointee.head_to_index?.pointee.new_file.path ?? "")
            } else {
                path = String(cString: entry.pointee.index_to_workdir?.pointee.new_file.path ?? "")
            }
            
            let state: String
            if status.rawValue & GIT_STATUS_INDEX_NEW.rawValue != 0 { state = "A" }
            else if status.rawValue & GIT_STATUS_INDEX_MODIFIED.rawValue != 0 { state = "M" }
            else if status.rawValue & GIT_STATUS_INDEX_DELETED.rawValue != 0 { state = "D" }
            else if status.rawValue & GIT_STATUS_INDEX_RENAMED.rawValue != 0 { state = "R" }
            else if status.rawValue & GIT_STATUS_INDEX_TYPECHANGE.rawValue != 0 { state = "T" }
            else if status.rawValue & GIT_STATUS_WT_NEW.rawValue != 0 { state = "??" }
            else { state = "U" }
            
            results.append((state, path))
        }
        
        return results
    }
    
    public func getCurrentBranch() throws -> String {
        guard let repo = repo else { throw GitError.branchFailed }
        
        var reference: OpaquePointer?
        guard git_repository_head(&reference, repo) == 0 else {
            throw GitError.branchFailed
        }
        defer { git_reference_free(reference) }
        
        guard let name = git_reference_shorthand(reference) else {
            throw GitError.branchFailed
        }
        
        return String(cString: name)
    }
    
    public func getBranches() throws -> [String] {
        guard let repo = repo else { throw GitError.branchFailed }
        
        var branches: OpaquePointer?
        guard git_branch_iterator_new(&branches, repo, GIT_BRANCH_LOCAL) == 0 else {
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
        
        return results
    }
    
    public func createBranch(name: String) throws {
        guard let repo = repo else { throw GitError.branchFailed }
        
        var commit: OpaquePointer?
        var head = git_oid()
        guard git_reference_name_to_id(&head, repo, "HEAD") == 0,
              git_commit_lookup(&commit, repo, &head) == 0 else {
            throw GitError.branchFailed
        }
        defer { git_commit_free(commit) }
        
        var branch: OpaquePointer?
        guard git_branch_create(&branch, repo, name, commit, 0) == 0 else {
            throw GitError.branchFailed
        }
        git_reference_free(branch)
    }
    
    public func checkoutBranch(name: String) throws {
        guard let repo = repo else { throw GitError.branchFailed }
        
        var reference: OpaquePointer?
        guard git_branch_lookup(&reference, repo, name, GIT_BRANCH_LOCAL) == 0 else {
            throw GitError.branchFailed
        }
        defer { git_reference_free(reference) }
        
        var opts = git_checkout_options()
        git_checkout_init_options(&opts, UInt32(GIT_CHECKOUT_OPTIONS_VERSION))
        
        guard git_checkout_tree(repo, nil, &opts) == 0,
              git_repository_set_head(repo, git_reference_name(reference)) == 0 else {
            throw GitError.branchFailed
        }
    }
    
    public func getFileHistory(file: String) throws -> [GitCommit] {
        guard let repo = repo else { throw GitError.historyFailed }
        
        var revwalk: OpaquePointer?
        guard git_revwalk_new(&revwalk, repo) == 0 else {
            throw GitError.historyFailed
        }
        defer { git_revwalk_free(revwalk) }
        
        git_revwalk_sorting(revwalk, GIT_SORT_TIME.rawValue | GIT_SORT_REVERSE.rawValue)
        
        var head = git_oid()
        guard git_reference_name_to_id(&head, repo, "HEAD") == 0 else {
            throw GitError.historyFailed
        }
        
        git_revwalk_push(revwalk, &head)
        
        var commits: [GitCommit] = []
        var oid = git_oid()
        
        while git_revwalk_next(&oid, revwalk) == 0 {
            var commit: OpaquePointer?
            guard git_commit_lookup(&commit, repo, &oid) == 0 else { continue }
            defer { git_commit_free(commit) }
            
            var parent: OpaquePointer?
            if git_commit_parent(&parent, commit, 0) == 0 {
                defer { git_commit_free(parent) }
                
                var diff: OpaquePointer?
                var diffOpts = git_diff_options()
                git_diff_init_options(&diffOpts, UInt32(GIT_DIFF_OPTIONS_VERSION))
                diffOpts.pathspec.count = 1
                try file.withCString { cPath in
                    var paths = [UnsafePointer<Int8>(cPath)]
                    diffOpts.pathspec.strings = UnsafeMutablePointer(mutating: &paths)
                    diffOpts.pathspec.count = 1
                    
                    guard let oldTree = git_commit_tree(parent),
                          let newTree = git_commit_tree(commit),
                          git_diff_tree_to_tree(&diff, repo, oldTree, newTree, &diffOpts) == 0 else {
                        throw GitError.diffFailed
                    }
                    defer { git_diff_free(diff) }
                    
                    if git_diff_num_deltas(diff) > 0 {
                        let hash = String(cString: git_oid_tostr_s(&oid))
                        let message = String(cString: git_commit_message(commit))
                        let author = String(cString: git_commit_author(commit).pointee.name)
                        let timestamp = git_commit_time(commit)
                        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateStyle = .medium
                        dateFormatter.timeStyle = .short
                        
                        commits.append(GitCommit(
                            commitHash: hash,
                            message: message,
                            author: author,
                            date: dateFormatter.string(from: date)
                        ))
                    }
                }
            }
        }
        
        return commits
    }
    
    public func getDiff(file: String) throws -> String {
        guard let repo = repo else { throw GitError.diffFailed }
        
        var head = git_oid()
        guard git_reference_name_to_id(&head, repo, "HEAD") == 0 else {
            throw GitError.diffFailed
        }
        
        var commit: OpaquePointer?
        guard git_commit_lookup(&commit, repo, &head) == 0 else {
            throw GitError.diffFailed
        }
        defer { git_commit_free(commit) }
        
        var diff: OpaquePointer?
        var opts = git_diff_options()
        git_diff_init_options(&opts, UInt32(GIT_DIFF_OPTIONS_VERSION))
        opts.pathspec.count = 1
        var diffResult = ""
        try file.withCString { cPath in
            var paths = [UnsafePointer<Int8>(cPath)]
            opts.pathspec.strings = UnsafeMutablePointer(mutating: &paths)
            opts.pathspec.count = 1
            
            guard let tree = git_commit_tree(commit),
                  git_diff_tree_to_workdir_with_index(&diff, repo, tree, &opts) == 0 else {
                throw GitError.diffFailed
            }
            defer { git_diff_free(diff) }
            
            let callback: git_diff_line_cb = { delta, hunk, line, payload in
                guard let line = line else { return 0 }
                let content = String(cString: line.pointee.content)
                let prefix: String
                switch git_diff_line_t(line.pointee.origin) {
                case GIT_DIFF_LINE_ADDITION: prefix = "+"
                case GIT_DIFF_LINE_DELETION: prefix = "-"
                default: prefix = " "
                }
                if let buffer = UnsafeMutablePointer<String>(OpaquePointer(payload)) {
                    buffer.pointee += prefix + content
                }
                return 0
            }
            
            _ = withUnsafeMutablePointer(to: &diffResult) { buffer in
                git_diff_print(diff, GIT_DIFF_FORMAT_PATCH, callback, buffer)
            }
        }
        
        return diffResult
    }
}
