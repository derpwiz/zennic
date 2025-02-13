//
//  WindowBox.swift
//  zennic
//

import AppKit
import SwiftUI

/// A class to wrap NSWindow in a reference type for SwiftUI observation
final class WindowBox: ObservableObject {
    weak var value: NSWindow?
    
    init(value: NSWindow?) {
        self.value = value
    }
}

/// A view modifier to observe window state changes
struct WindowObserver<Content: View>: View {
    @ObservedObject var window: WindowBox
    let content: () -> Content
    
    init(window: WindowBox, @ViewBuilder content: @escaping () -> Content) {
        self.window = window
        self.content = content
    }
    
    var body: some View {
        content()
            .onChange(of: window.value?.isKeyWindow) { _ in
                // Trigger view update when window key status changes
                window.objectWillChange.send()
            }
            .onChange(of: window.value?.isVisible) { _ in
                // Trigger view update when window visibility changes
                window.objectWillChange.send()
            }
    }
}

extension View {
    /// Adds window observation to a view
    func observingWindow(_ window: WindowBox) -> some View {
        WindowObserver(window: window) {
            self
        }
    }
}
