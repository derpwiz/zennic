import SwiftUI

public struct SplitView {
    public struct Horizontal<Content: View>: View {
        let content: Content
        
        public init(@ViewBuilder content: () -> Content) {
            self.content = content()
        }
        
        public var body: some View {
            VStack {
                content.variadic { children in
                    SplitViewControllerView(axis: .horizontal, children: children, viewController: .constant({ nil }))
                }
            }
            ._trait(SplitViewControllerLayoutValueKey.self, { nil })
            .accessibilityElement(children: .contain)
        }
    }
    
    public struct Vertical<Content: View>: View {
        let content: Content
        
        public init(@ViewBuilder content: () -> Content) {
            self.content = content()
        }
        
        public var body: some View {
            VStack {
                content.variadic { children in
                    SplitViewControllerView(axis: .vertical, children: children, viewController: .constant({ nil }))
                }
            }
            ._trait(SplitViewControllerLayoutValueKey.self, { nil })
            .accessibilityElement(children: .contain)
        }
    }
    
    public static func horizontal<Content: View>(@ViewBuilder content: () -> Content) -> Horizontal<Content> {
        Horizontal(content: content)
    }
    
    public static func vertical<Content: View>(@ViewBuilder content: () -> Content) -> Vertical<Content> {
        Vertical(content: content)
    }
}
