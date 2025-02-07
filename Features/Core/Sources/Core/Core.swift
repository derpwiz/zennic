import Foundation
import SwiftUI
import Shared

public class AppState: ObservableObject {
    @Published public var isDarkMode: Bool = false
    @Published public var selectedFeature: String? = nil
    @Published public var currentLanguage: CodeLanguage = .python
    @Published public var currentCode: String = ""
    public static let shared = AppState()
    
    public init() {}
    
    public func getCodeHistory(language: CodeLanguage) -> [String]? {
        // For now, return empty array. This can be expanded later to actually store history
        return []
    }
}

// Export Core module's public interface
public enum Core {
    public static let shared = GitService.shared
    public static let appState = AppState.shared
    
    // Re-export Git types from module scope
    public typealias GitServiceType = GitService
    public typealias GitErrorType = GitError
    public typealias GitCommitType = GitCommit
    public typealias GitStatusType = GitStatus
    public typealias GitWrapperType = GitWrapper
}
