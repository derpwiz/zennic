import SwiftUI
import AppKit

/// A protocol defining the public interface for split view controllers
public protocol SplitViewControllerType: AnyObject {
    /// The underlying NSSplitView
    var splitView: NSSplitView { get }
    
    /// Collapses or expands a view in the split view
    /// - Parameters:
    ///   - id: The id of the view to collapse/expand
    ///   - enabled: Whether to collapse (true) or expand (false) the view
    func collapse(for id: AnyHashable, enabled: Bool)
}
