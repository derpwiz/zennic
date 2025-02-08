import SwiftUI
import Foundation
import Combine
import Core

/// Manages the state and business logic for the code editor
public class CodeEditorViewModel: ObservableObject {
    public let gitWrapper: GitWrapper
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Published Properties
    
    @Published public var content: String = ""
    @Published public var currentBranch: String?
    @Published public var fileStatus: String?
    @Published public var selectedFile: String?
    @Published public var files: [(path: String, isDirectory: Bool)] = []
    
    /// Scan directory for files
    /// - Parameter path: Directory path to scan
    public func scanDirectory(path: String) {
        do {
            let fileManager = FileManager.default
            let contents = try fileManager.contentsOfDirectory(atPath: path)
            
            files = try contents.map { item in
                let fullPath = (path as NSString).appendingPathComponent(item)
                var isDirectory: ObjCBool = false
                fileManager.fileExists(atPath: fullPath, isDirectory: &isDirectory)
                return (path: fullPath, isDirectory: isDirectory.boolValue)
            }.sorted { lhs, rhs in
                // Directories first, then alphabetically
                if lhs.isDirectory != rhs.isDirectory {
                    return lhs.isDirectory
                }
                return lhs.path < rhs.path
            }
        } catch {
            print("Error scanning directory: \(error)")
            files = []
        }
    }
    
    // MARK: - Initialization
    
    public init(gitWrapper: GitWrapper) {
        self.gitWrapper = gitWrapper
        setupGitObservers()
    }
    
    // MARK: - Private Methods
    
    private func setupGitObservers() {
        // Update branch info
        Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateGitStatus()
            }
            .store(in: &cancellables)
    }
    
    private func updateGitStatus() {
        do {
            currentBranch = try gitWrapper.getCurrentBranch()
            
            if let selectedFile = selectedFile {
                let status = try gitWrapper.getStatus()
                fileStatus = status.first { $0.1 == selectedFile }?.0
            }
        } catch {
            print("Error updating Git status: \(error)")
        }
    }
    
    // MARK: - Public Methods
    
    /// Load content from a file
    /// - Parameter path: Path to the file
    public func loadFile(at path: String) {
        do {
            content = try String(contentsOfFile: path, encoding: .utf8)
            selectedFile = path
            updateGitStatus()
        } catch {
            print("Error loading file: \(error)")
        }
    }
    
    /// Save content to a file
    /// - Parameter path: Path to save the file
    public func saveFile(to path: String) {
        do {
            try content.write(toFile: path, atomically: true, encoding: .utf8)
            try gitWrapper.add(file: path)
            updateGitStatus()
        } catch {
            print("Error saving file: \(error)")
        }
    }
    
    /// Commit changes with a message
    /// - Parameter message: Commit message
    public func commit(message: String) {
        do {
            try gitWrapper.commit(message: message)
            updateGitStatus()
        } catch {
            print("Error committing changes: \(error)")
        }
    }
    
    /// Get file history
    /// - Parameter path: Path to the file
    /// - Returns: Array of commits that modified the file
    public func getHistory(for path: String) throws -> [GitCommit] {
        return try gitWrapper.getFileHistory(file: path)
    }
    
    /// Get diff for a file
    /// - Parameter path: Path to the file
    /// - Returns: String containing the unified diff
    public func getDiff(for path: String) throws -> String {
        return try gitWrapper.getDiff(file: path)
    }
}
