import Foundation

/// Unique identifier for editor tabs
public enum EditorTabID: Codable, Identifiable, Hashable {
    case file(String)
    case untitled(UUID)
    
    public var id: String {
        switch self {
        case .file(let path):
            return path
        case .untitled(let uuid):
            return uuid.uuidString
        }
    }
}
