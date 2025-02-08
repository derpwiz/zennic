import Foundation
import SwiftUI

public class AppState: ObservableObject {
    public static let shared = AppState()
    
    @Published public var selectedFeature: String?
    @Published public var isDarkMode: Bool = false
    @Published public var workspacePath: String = FileManager.default.currentDirectoryPath
    
    private init() {}
    
    public func setWorkspacePath(_ path: String) {
        workspacePath = path
    }
}
