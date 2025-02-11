import SwiftUI

/// A view that provides access to a split view controller
public struct SplitViewReader<Content: View>: View {
    @StateObject private var proxy: SplitViewProxy
    private let content: (SplitViewProxy) -> Content
    
    /// Creates a new split view reader
    /// - Parameter content: A closure that creates content using the provided controller proxy
    public init(@ViewBuilder content: @escaping (SplitViewProxy) -> Content) {
        self._proxy = StateObject(wrappedValue: SplitViewProxy())
        self.content = content
    }
    
    public var body: some View {
        content(proxy)
            .onPreferenceChange(SplitViewControllerLayoutValueKey.self) { reference in
                if let controller = reference?.controller {
                    proxy.controller = controller
                }
            }
    }
}

/// A proxy object that provides access to a split view controller
public class SplitViewProxy: ObservableObject {
    /// The current controller
    var controller: SplitViewControllerProtocol?
    
    /// Sets the position of a split view item
    /// - Parameters:
    ///   - id: The identifier of the item
    ///   - position: The new position
    public func setPosition(of id: String, position: CGFloat) {
        controller?.setPosition(of: id, position: position)
    }
    
    /// Collapses or expands a split view item
    /// - Parameters:
    ///   - id: The identifier of the item
    ///   - enabled: Whether the item should be collapsed
    public func collapse(for id: String, enabled: Bool) {
        controller?.collapse(for: id, enabled: enabled)
    }
}
