import Foundation
import Cgit2

@objc public class GitService: NSObject {
    @objc public static let shared = GitService()
    private var repositories: [String: GitWrapper] = [:]
    
    private override init() {}
    
    private func getRepository(at path: String) throws -> GitWrapper {
        if let repo = repositories[path] {
            return repo
        }
        
        let repo = try GitWrapper(path: path)
        repositories[path] = repo
        return repo
    }
    
    @objc public func initRepository(at path: String) throws {
        _ = try GitWrapper(path: path)
    }
    
    @objc public func addFile(_ file: String, at path: String) throws {
        let repo = try getRepository(at: path)
        try repo.add(file: file)
    }
    
    @objc public func commit(message: String, at path: String) throws {
        let repo = try getRepository(at: path)
        try repo.commit(message: message)
    }
    
    @objc public func readFile(name: String) throws -> String {
        let codeDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("ZennicCode")
        let fileURL = codeDirectory.appendingPathComponent(name)
        
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            throw GitError.fileNotFound
        }
        
        do {
            return try String(contentsOf: fileURL, encoding: .utf8)
        } catch {
            throw GitError.fileReadFailed
        }
    }
    
    @objc public func updateFile(name: String, content: String) throws {
        let codeDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("ZennicCode")
        let fileURL = codeDirectory.appendingPathComponent(name)
        
        // Ensure directory exists
        if !FileManager.default.fileExists(atPath: codeDirectory.path) {
            try FileManager.default.createDirectory(at: codeDirectory, withIntermediateDirectories: true)
            try initRepository(at: codeDirectory.path)
        }
        
        do {
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
            try addFile(name, at: codeDirectory.path)
            try commit(message: "Updated \(name)", at: codeDirectory.path)
        } catch {
            throw GitError.fileWriteFailed
        }
    }
    
    @objc public func getStatus(at path: String) throws -> [GitStatus] {
        let repo = try getRepository(at: path)
        return try repo.getStatus().map { GitStatus(state: $0.0, file: $0.1) }
    }
    
    @objc public func getCurrentBranch(at path: String) throws -> String {
        let repo = try getRepository(at: path)
        return try repo.getCurrentBranch()
    }
    
    @objc public func getBranches(at path: String) throws -> [String] {
        let repo = try getRepository(at: path)
        return try repo.getBranches()
    }
    
    @objc public func createBranch(name: String, at path: String) throws {
        let repo = try getRepository(at: path)
        try repo.createBranch(name: name)
    }
    
    @objc public func checkoutBranch(name: String, at path: String) throws {
        let repo = try getRepository(at: path)
        try repo.checkoutBranch(name: name)
    }
    
    @objc public func listFiles() throws -> [String] {
        let codeDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("ZennicCode")
        
        if !FileManager.default.fileExists(atPath: codeDirectory.path) {
            try FileManager.default.createDirectory(at: codeDirectory, withIntermediateDirectories: true)
            try initRepository(at: codeDirectory.path)
            return []
        }
        
        let contents = try FileManager.default.contentsOfDirectory(atPath: codeDirectory.path)
        return contents.filter { !$0.hasPrefix(".") } // Filter out hidden files
    }
    
    @objc public func createFile(name: String, content: String) throws {
        try updateFile(name: name, content: content)
    }
    
    @objc public func deleteFile(name: String) throws {
        let codeDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("ZennicCode")
        let fileURL = codeDirectory.appendingPathComponent(name)
        
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            throw GitError.fileNotFound
        }
        
        try FileManager.default.removeItem(at: fileURL)
        try addFile(name, at: codeDirectory.path)
        try commit(message: "Deleted \(name)", at: codeDirectory.path)
    }
    
    @objc public func getFileHistory(file: String, at path: String) throws -> [GitCommit] {
        let repo = try getRepository(at: path)
        return try repo.getFileHistory(file: file)
    }
    
    @objc public func getDiff(file: String, at path: String) throws -> String {
        let repo = try getRepository(at: path)
        return try repo.getDiff(file: file)
    }
}
@objc public class GitCommit: NSObject {
    @objc public let commitHash: String
    @objc public let message: String
    @objc public let author: String
    @objc public let date: String
    
    @objc public init(commitHash: String, message: String, author: String, date: String) {
        self.commitHash = commitHash
        self.message = message
        self.author = author
        self.date = date
        super.init()
    }
}

@objc public class GitStatus: NSObject {
    @objc public let state: String
    @objc public let file: String
    
    @objc public init(state: String, file: String) {
        self.state = state
        self.file = file
        super.init()
    }
    
    @objc public override var description: String {
        switch state {
        case "M": return "Modified"
        case "A": return "Added"
        case "D": return "Deleted"
        case "R": return "Renamed"
        case "C": return "Copied"
        case "U": return "Updated"
        case "??": return "Untracked"
        default: return "Unknown"
        }
    }
}

@objc public enum GitError: Int, Error {
    case initFailed
    case addFailed
    case commitFailed
    case historyFailed
    case statusFailed
    case diffFailed
    case branchFailed
    case fileReadFailed
    case fileWriteFailed
    case fileNotFound
}

extension GitError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .initFailed:
            return "Failed to initialize git repository"
        case .addFailed:
            return "Failed to add file to git"
        case .commitFailed:
            return "Failed to commit changes"
        case .historyFailed:
            return "Failed to retrieve file history"
        case .statusFailed:
            return "Failed to get git status"
        case .diffFailed:
            return "Failed to get file diff"
        case .branchFailed:
            return "Failed to perform branch operation"
        case .fileReadFailed:
            return "Failed to read file contents"
        case .fileWriteFailed:
            return "Failed to write file contents"
        case .fileNotFound:
            return "File not found"
        }
    }
}
