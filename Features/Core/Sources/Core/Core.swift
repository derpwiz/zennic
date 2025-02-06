import Foundation
import SwiftUI
@_implementationOnly import Shared

// Internal type alias to avoid exposing Shared.CodeLanguage in public interface
private typealias SharedCodeLanguage = CodeLanguage

public class AppState: ObservableObject {
    @Published public var isDarkMode: Bool = false
    @Published public var selectedFeature: String? = nil
    @Published public var currentLanguage: String = "python"
    @Published public var currentCode: String = ""
    public static let shared = AppState()
    
    public init() {}
    
    public func getCodeHistory(language: String) -> [String]? {
        let codeLanguage = SharedCodeLanguage(rawValue: language)
        // For now, return empty array. This can be expanded later to actually store history
        return []
    }
}

// Export Core module's public interface
public enum Core {
    public static let shared = GitService.shared
    
    // Re-export Git types from module scope
    public typealias GitServiceType = GitService
    public typealias GitErrorType = GitError
    public typealias GitCommitType = GitCommit
    public typealias GitStatusType = GitStatus
}
