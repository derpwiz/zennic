import SwiftUI

/// A view that provides access to the parent split view controller
public struct SplitViewReader<Content: View>: View {
    /// The content to display
    private let content: (SplitViewController?) -> Content
    
    /// Creates a new split view reader
    /// - Parameter content: A closure that takes a split view controller and returns a view
    public init(@ViewBuilder content: @escaping (SplitViewController?) -> Content) {
        self.content = content
    }
    
    public var body: some View {
        content(viewController)
            .environment(\.splitViewController, viewController)
    }
    
    /// The parent split view controller
    private var viewController: SplitViewController? {
        let value = self[SplitViewControllerLayoutValueKey.self]
        return value()
    }
}

/// Environment key for accessing the split view controller
private struct SplitViewControllerKey: EnvironmentKey {
    static let defaultValue: SplitViewController? = nil
}

extension EnvironmentValues {
    /// The current split view controller
    var splitViewController: SplitViewController? {
        get { self[SplitViewControllerKey.self] }
        set { self[SplitViewControllerKey.self] = newValue }
    }
}

/// Extension to provide convenience methods for collapsing/expanding views
public extension View {
    /// Collapses or expands this view in its parent split view
    /// - Parameter isCollapsed: Whether the view should be collapsed
    /// - Returns: A modified view that can be collapsed/expanded
    func collapsed(_ isCollapsed: Bool) -> some View {
        modifier(CollapsedModifier(isCollapsed: isCollapsed))
    }
}

/// A view modifier that handles collapsing/expanding views
private struct CollapsedModifier: ViewModifier {
    /// The environment's split view controller
    @Environment(\.splitViewController) private var splitViewController
    
    /// Whether the view should be collapsed
    let isCollapsed: Bool
    
    func body(content: Content) -> some View {
        content.id("split-view-item-\(isCollapsed)")
            .onAppear {
                splitViewController?.collapse(
                    for: "split-view-item-\(isCollapsed)",
                    enabled: isCollapsed
                )
            }
            .onChange(of: isCollapsed) { newValue in
                splitViewController?.collapse(
                    for: "split-view-item-\(isCollapsed)",
                    enabled: newValue
                )
            }
    }
}

#Preview {
    SplitView.horizontal {
        Color.red
            .frame(minWidth: 200, maxWidth: 300)
        
        SplitViewReader { controller in
            Color.blue
                .frame(maxWidth: .infinity)
                .overlay(alignment: .topLeading) {
                    Button("Toggle Left") {
                        controller?.collapse(for: "split-view-item-true", enabled: true)
                    }
                    .padding()
                }
        }
        
        Color.green
            .frame(width: 200)
            .collapsed(true)
    }
    .frame(width: 800, height: 400)
}
