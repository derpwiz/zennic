import SwiftUI

/// A view that provides access to a split view controller
public struct SplitViewReader<Content: View>: View {
    @StateObject private var proxy: SplitViewProxy
    private let content: (SplitViewProxy) -> Content

    public init(@ViewBuilder content: @escaping (SplitViewProxy) -> Content) {
        self._proxy = StateObject(wrappedValue: SplitViewProxy(viewController: { nil }))
        self.content = content
    }

    public var body: some View {
        content(proxy)
            .onPreferenceChange(SplitViewControllerLayoutValueKey.self) { value in
                proxy.setPosition(of: 0, position: 0) // Trigger update
            }
    }
}
