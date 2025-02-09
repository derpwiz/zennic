import SwiftUI

/// A view that provides its content with a proxy for reading split view state.
public struct SplitViewReader<Content: View>: View {
    private let content: (SplitViewProxy) -> Content
    @StateObject private var proxy = SplitViewProxy()
    
    /// Creates a split view reader with the given content.
    /// - Parameter content: A closure that creates content using the proxy.
    public init(@ViewBuilder content: @escaping (SplitViewProxy) -> Content) {
        self.content = content
    }
    
    public var body: some View {
        content(proxy)
            .environmentObject(proxy)
    }
}

/// A proxy object that provides access to split view state.
public final class SplitViewProxy: ObservableObject {
    @Published public private(set) var isCollapsed = false
    @Published public private(set) var isMaximized = false
    
    /// Toggles the collapsed state.
    public func toggleCollapsed() {
        isCollapsed.toggle()
    }
    
    /// Toggles the maximized state.
    public func toggleMaximized() {
        isMaximized.toggle()
    }
    
    /// Sets the collapsed state.
    /// - Parameter collapsed: The new collapsed state.
    public func setCollapsed(_ collapsed: Bool) {
        isCollapsed = collapsed
    }
    
    /// Sets the maximized state.
    /// - Parameter maximized: The new maximized state.
    public func setMaximized(_ maximized: Bool) {
        isMaximized = maximized
    }
}

/// A view modifier that makes a view collapsable.
public struct CollapsableModifier: ViewModifier {
    @Binding var collapsed: Bool
    
    public func body(content: Content) -> some View {
        content
            .frame(height: collapsed ? 0 : nil)
            .opacity(collapsed ? 0 : 1)
    }
}

extension View {
    /// Makes this view collapsable.
    /// - Parameter collapsed: A binding to the collapsed state.
    /// - Returns: A view that can be collapsed.
    public func collapsable() -> some View {
        modifier(CollapsableModifier(collapsed: .constant(false)))
    }
    
    /// Makes this view collapsable.
    /// - Parameter collapsed: A binding to the collapsed state.
    /// - Returns: A view that can be collapsed.
    public func collapsed(_ collapsed: Binding<Bool>) -> some View {
        modifier(CollapsableModifier(collapsed: collapsed))
    }
}
