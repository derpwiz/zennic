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
    
    func readFile(name: String) throws -> String {
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
    
    func updateFile(name: String, content: String) throws {
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
    case fileReadFailed
    case fileWriteFailed
    case fileNotFound
    
    var localizedDescription: String {
        switch self {
        case .initFailed:
            return "Failed to initialize git repository"
        case .addFailed:
            return "Failed to add file to git"
        case .commitFailed:
            return "Failed to commit changes"
        case .historyFailed:
            return "Failed to retrieve file history"
        case .fileReadFailed:
            return "Failed to read file contents"
        case .fileWriteFailed:
            return "Failed to write file contents"
        case .fileNotFound:
            return "File not found"
        }
    }
}
