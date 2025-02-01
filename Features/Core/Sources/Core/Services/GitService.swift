import Foundation

public class GitService {
    public static let shared = GitService()
    
    private init() {}
    
    public func initRepository(at path: String) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.arguments = ["init", path]
        
        try process.run()
        process.waitUntilExit()
        
        if process.terminationStatus != 0 {
            throw GitError.initFailed
        }
    }
    
    public func addFile(_ file: String, at path: String) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.arguments = ["-C", path, "add", file]
        
        try process.run()
        process.waitUntilExit()
        
        if process.terminationStatus != 0 {
            throw GitError.addFailed
        }
    }
    
    public func commit(message: String, at path: String) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.arguments = ["-C", path, "commit", "-m", message]
        
        try process.run()
        process.waitUntilExit()
        
        if process.terminationStatus != 0 {
            throw GitError.commitFailed
        }
    }
    
    public func readFile(name: String) throws -> String {
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
    
    public func updateFile(name: String, content: String) throws {
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
    
    public func getFileHistory(file: String, at path: String) throws -> [GitCommit] {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.arguments = ["-C", path, "log", "--pretty=format:%h|%s|%an|%ad", "--date=iso", file]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        
        try process.run()
        process.waitUntilExit()
        
        if process.terminationStatus != 0 {
            throw GitError.historyFailed
        }
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""
        
        return output.components(separatedBy: .newlines)
            .filter { !$0.isEmpty }
            .compactMap { line -> GitCommit? in
                let parts = line.components(separatedBy: "|")
                guard parts.count == 4 else { return nil }
                return GitCommit(
                    hash: parts[0],
                    message: parts[1],
                    author: parts[2],
                    date: parts[3]
                )
            }
    }
    
    public func getStatus(at path: String) throws -> [GitStatus] {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.arguments = ["-C", path, "status", "--porcelain"]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        
        try process.run()
        process.waitUntilExit()
        
        if process.terminationStatus != 0 {
            throw GitError.statusFailed
        }
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""
        
        return output.components(separatedBy: .newlines)
            .filter { !$0.isEmpty }
            .compactMap { line -> GitStatus? in
                guard line.count >= 3 else { return nil }
                let state = String(line.prefix(2)).trimmingCharacters(in: .whitespaces)
                let file = String(line.dropFirst(3))
                return GitStatus(state: state, file: file)
            }
    }
    
    public func getDiff(file: String, at path: String) throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.arguments = ["-C", path, "diff", "--color=never", file]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        
        try process.run()
        process.waitUntilExit()
        
        if process.terminationStatus != 0 {
            throw GitError.diffFailed
        }
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8) ?? ""
    }
    
    public func getCurrentBranch(at path: String) throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.arguments = ["-C", path, "rev-parse", "--abbrev-ref", "HEAD"]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        
        try process.run()
        process.waitUntilExit()
        
        if process.terminationStatus != 0 {
            throw GitError.branchFailed
        }
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return (String(data: data, encoding: .utf8) ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    public func getBranches(at path: String) throws -> [String] {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.arguments = ["-C", path, "branch", "--format=%(refname:short)"]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        
        try process.run()
        process.waitUntilExit()
        
        if process.terminationStatus != 0 {
            throw GitError.branchFailed
        }
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return (String(data: data, encoding: .utf8) ?? "")
            .components(separatedBy: .newlines)
            .filter { !$0.isEmpty }
    }
    
    public func createBranch(name: String, at path: String) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.arguments = ["-C", path, "checkout", "-b", name]
        
        try process.run()
        process.waitUntilExit()
        
        if process.terminationStatus != 0 {
            throw GitError.branchFailed
        }
    }
    
    public func checkoutBranch(name: String, at path: String) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.arguments = ["-C", path, "checkout", name]
        
        try process.run()
        process.waitUntilExit()
        
        if process.terminationStatus != 0 {
            throw GitError.branchFailed
        }
    }
    
    public func listFiles() throws -> [String] {
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
    
    public func createFile(name: String, content: String) throws {
        try updateFile(name: name, content: content)
    }
    
    public func deleteFile(name: String) throws {
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
}
public struct GitCommit {
    public let hash: String
    public let message: String
    public let author: String
    public let date: String
    
    public init(hash: String, message: String, author: String, date: String) {
        self.hash = hash
        self.message = message
        self.author = author
        self.date = date
    }
}

public struct GitStatus {
    public let state: String
    public let file: String
    
    public init(state: String, file: String) {
        self.state = state
        self.file = file
    }
    
    public var description: String {
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

public enum GitError: Error {
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
    
    public var localizedDescription: String {
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
