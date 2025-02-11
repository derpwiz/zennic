import SwiftUI

/// A wrapper type that makes a split view controller reference Equatable
public struct SplitViewControllerReference: Equatable {
    /// Unique identifier for Equatable conformance
    private let id = UUID()
    
    /// The wrapped controller
    let controller: SplitViewControllerProtocol
    
    /// Creates a new reference to a split view controller
    /// - Parameter controller: The controller to wrap
    public init(controller: SplitViewControllerProtocol) {
        self.controller = controller
    }
    
    /// Equatable conformance based on id
    public static func == (lhs: SplitViewControllerReference, rhs: SplitViewControllerReference) -> Bool {
        lhs.id == rhs.id
    }
}
