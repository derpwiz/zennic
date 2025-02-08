import XCTest
import Core
@testable import CodeEditor

final class CodeEditorViewModelTests: XCTestCase {
    var tempDir: String!
    var gitWrapper: GitWrapper!
    var viewModel: CodeEditorViewModel!
    
    override func setUp() async throws {
        // Create a temporary directory for testing
        tempDir = NSTemporaryDirectory().appending("CodeEditorTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(atPath: tempDir, withIntermediateDirectories: true)
        
        // Initialize Git repo
        gitWrapper = try GitWrapper(path: tempDir)
        viewModel = CodeEditorViewModel(gitWrapper: gitWrapper)
    }
    
    override func tearDown() async throws {
        // Clean up temporary directory
        try? FileManager.default.removeItem(atPath: tempDir)
    }
    
    func testScanDirectory() throws {
        // Create some test files
        let file1 = (tempDir as NSString).appendingPathComponent("test1.swift")
        let file2 = (tempDir as NSString).appendingPathComponent("test2.md")
        let subdir = (tempDir as NSString).appendingPathComponent("subdir")
        
        try "Test content 1".write(toFile: file1, atomically: true, encoding: .utf8)
        try "Test content 2".write(toFile: file2, atomically: true, encoding: .utf8)
        try FileManager.default.createDirectory(atPath: subdir, withIntermediateDirectories: false)
        
        // Scan directory
        viewModel.scanDirectory(path: tempDir)
        
        // Verify results
        XCTAssertEqual(viewModel.files.count, 3)
        XCTAssert(viewModel.files.contains { $0.path.hasSuffix("test1.swift") && !$0.isDirectory })
        XCTAssert(viewModel.files.contains { $0.path.hasSuffix("test2.md") && !$0.isDirectory })
        XCTAssert(viewModel.files.contains { $0.path.hasSuffix("subdir") && $0.isDirectory })
    }
    
    func testLoadAndSaveFile() throws {
        // Create test file
        let testFile = (tempDir as NSString).appendingPathComponent("test.txt")
        let testContent = "Test content"
        try testContent.write(toFile: testFile, atomically: true, encoding: .utf8)
        
        // Load file
        viewModel.loadFile(at: testFile)
        XCTAssertEqual(viewModel.content, testContent)
        XCTAssertEqual(viewModel.selectedFile, testFile)
        
        // Modify and save
        let newContent = "Modified content"
        viewModel.content = newContent
        viewModel.saveFile(to: testFile)
        
        // Verify file was saved
        let savedContent = try String(contentsOfFile: testFile, encoding: .utf8)
        XCTAssertEqual(savedContent, newContent)
        
        // Verify Git status
        let status = try gitWrapper.getStatus()
        XCTAssert(status.contains { $0.1 == testFile })
    }
    
    func testGitIntegration() throws {
        // Create and add a file
        let testFile = (tempDir as NSString).appendingPathComponent("test.txt")
        try "Initial content".write(toFile: testFile, atomically: true, encoding: .utf8)
        try gitWrapper.add(file: testFile)
        try gitWrapper.commit(message: "Initial commit")
        
        // Modify file
        try "Modified content".write(toFile: testFile, atomically: true, encoding: .utf8)
        
        // Load file and check status
        viewModel.loadFile(at: testFile)
        XCTAssertEqual(viewModel.fileStatus, "M")
        
        // Get current branch
        let branch = try gitWrapper.getCurrentBranch()
        XCTAssertEqual(viewModel.currentBranch, branch)
    }
}
