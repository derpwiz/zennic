import SwiftUI

public struct WindowTitleBarStyle: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    
    public init() {}
    
    public func body(content: Content) -> some View {
        content
            .background {
                EffectView(.windowBackground)
                    .ignoresSafeArea()
            }
            .toolbar {
                ToolbarItem(placement: .navigation) {
                    EmptyView()
                }
                ToolbarItem(placement: .primaryAction) {
                    EmptyView()
                }
            }
            .toolbarBackground(.hidden, for: .windowToolbar)
    }
}

public extension View {
    func windowTitleBarStyle() -> some View {
        modifier(WindowTitleBarStyle())
    }
}
