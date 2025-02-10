import SwiftUI
import Foundation
import Combine
import Core
import Shared

/// Manages the state and business logic for the code editor
public class CodeEditorViewModel: ObservableObject, Loggable {
    public var gitWrapper: GitWrapper?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Published Properties
    
    @Published public var content: String = ""
    @Published public var error: String?
    @Published public var currentBranch: String?
    @Published public var fileStatus: String?
    @Published public var selectedFile: String?
    @Published public var files: [(path: String, isDirectory: Bool)] = []
    
    // Status bar properties
    @Published public var cursorLine: Int = 1
    @Published public var cursorColumn: Int = 1
    @Published public var characterOffset: Int = 0
    @Published public var selectedLength: Int = 0
    @Published public var selectedLines: Int = 0
    @Published public var fileSize: Int?
    
    /// Scan directory for files
    /// - Parameter path: Directory path to scan
    public func scanDirectory(path: String) {
        do {
            let fileManager = FileManager.default
            let contents = try fileManager.contentsOfDirectory(atPath: path)
            
            files = contents.map { item in
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
            files = []
        }
    }
    
    // MARK: - Initialization
    
    private let workspacePath: String
    
    public init(workspacePath: String) {
        self.workspacePath = workspacePath
        self.gitWrapper = nil
        
        // Create directory if it doesn't exist
        if !FileManager.default.fileExists(atPath: workspacePath) {
            try? FileManager.default.createDirectory(at: URL(fileURLWithPath: workspacePath), withIntermediateDirectories: true)
        }
        setupGitObservers()
        setupContentObserver()
    }
    
    /// Sets up an observer for content changes to update cursor information
    private func setupContentObserver() {
        $content
            .sink { [weak self] _ in
                self?.updateCursorInfo()
            }
            .store(in: &cancellables)
    }
    
    /// Updates cursor position and selection information
    private func updateCursorInfo() {
        // TODO: Implement cursor position tracking
        // This would typically be done through a NSTextView delegate
        // or similar mechanism that can track the selection range
    }
    
    /// Updates file size information
    private func updateFileInfo() {
        guard let selectedFile = selectedFile else { return }
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: selectedFile)
            fileSize = attributes[.size] as? Int
        } catch {
            // Handle error silently
        }
    }
    
    /// Initialize Git repository in the workspace
    /// - Returns: True if initialization was successful
    @discardableResult
    public func initializeGit() -> Bool {
        do {
            self.gitWrapper = try GitWrapper(path: workspacePath)
            return true
        } catch {
            self.error = "Failed to initialize Git repository: \(error.localizedDescription)"
            return false
        }
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
        guard let gitWrapper = gitWrapper else { return }
        do {
            currentBranch = try gitWrapper.getCurrentBranch()
            
            if let selectedFile = selectedFile {
                let status = try gitWrapper.getStatus()
                fileStatus = status.first { $0.1 == selectedFile }?.0
            }
        } catch {
            // Handle error silently
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
            updateFileInfo()
        } catch {
            // Handle error silently
        }
    }
    
    /// Save content to a file
    /// - Parameter path: Path to save the file
    public func saveFile(to path: String) {
        guard let gitWrapper = gitWrapper else { return }
        do {
            try content.write(toFile: path, atomically: true, encoding: .utf8)
            try gitWrapper.add(file: path)
            updateGitStatus()
        } catch {
            // Handle error silently
        }
    }
    
    /// Commit changes with a message
    /// - Parameter message: Commit message
    public func commit(message: String) {
        guard let gitWrapper = gitWrapper else { return }
        do {
            try gitWrapper.commit(message: message)
            updateGitStatus()
        } catch {
            // Handle error silently
        }
    }
    
    /// Get file history
    /// - Parameter path: Path to the file
    /// - Returns: Array of commits that modified the file
    public func getHistory(for path: String) throws -> [GitCommit] {
        guard let gitWrapper = gitWrapper else {
            throw GitError.initFailed
        }
        return try gitWrapper.getFileHistory(file: path)
    }
    
    /// Get diff for a file
    /// - Parameter path: Path to the file
    /// - Returns: String containing the unified diff
    public func getDiff(for path: String) throws -> String {
        guard let gitWrapper = gitWrapper else {
            throw GitError.initFailed
        }
        return try gitWrapper.getDiff(file: path)
    }
}
