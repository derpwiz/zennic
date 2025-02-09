import SwiftUI

/// A view modifier that adds press and release gesture actions to a view
struct PressActions: ViewModifier {
    /// The action to perform when the view is pressed
    var onPress: () -> Void
    
    /// The action to perform when the press is released
    var onRelease: (() -> Void)?
    
    /// Creates a new press actions modifier
    /// - Parameters:
    ///   - onPress: Action to perform when the view is pressed
    ///   - onRelease: Optional action to perform when the press is released
    init(
        onPress: @escaping () -> Void,
        onRelease: (() -> Void)? = nil
    ) {
        self.onPress = onPress
        self.onRelease = onRelease
    }
    
    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in onPress() }
                    .onEnded { _ in onRelease?() }
            )
    }
}

public extension View {
    /// Adds press and release gesture actions to a view
    /// - Parameters:
    ///   - onPress: Action to perform when the view is pressed
    ///   - onRelease: Optional action to perform when the press is released
    /// - Returns: A modified view that responds to press gestures
    func pressAction(
        onPress: @escaping () -> Void,
        onRelease: (() -> Void)? = nil
    ) -> some View {
        modifier(PressActions(onPress: onPress, onRelease: onRelease))
    }
}
