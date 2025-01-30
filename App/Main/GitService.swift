import Foundation

class GitService {
    static let shared = GitService()
    
    private init() {}
    
    func initRepository(at path: String) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.arguments = ["init", path]
        
        try process.run()
        process.waitUntilExit()
        
        if process.terminationStatus != 0 {
            throw GitError.initFailed
        }
    }
    
    func addFile(_ file: String, at path: String) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.arguments = ["-C", path, "add", file]
        
        try process.run()
        process.waitUntilExit()
        
        if process.terminationStatus != 0 {
            throw GitError.addFailed
        }
    }
    
    func commit(message: String, at path: String) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.arguments = ["-C", path, "commit", "-m", message]
        
        try process.run()
        process.waitUntilExit()
        
        if process.terminationStatus != 0 {
            throw GitError.commitFailed
        }
    }
    
    func getFileHistory(file: String, at path: String) throws -> [String] {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.arguments = ["-C", path, "log", "--pretty=format:%h %s", file]
        
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
    }
}

enum GitError: Error {
    case initFailed
    case addFailed
    case commitFailed
    case historyFailed
}
