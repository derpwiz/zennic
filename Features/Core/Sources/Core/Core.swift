import Foundation
import SwiftUI
import Shared

// Export Core module's public interface
public enum Core {
    public static let shared = GitService.shared
    
    // Re-export Git types from module scope
    public typealias GitServiceType = GitService
    public typealias GitErrorType = GitError
    public typealias GitCommitType = GitCommit
    public typealias GitStatusType = GitStatus
    public typealias GitWrapperType = GitWrapper
}
