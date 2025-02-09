import SwiftUI

/// A divider view that adapts its appearance based on the current color scheme
public struct PanelDivider: View {
    @Environment(\.colorScheme)
    private var colorScheme
    
    private let color: Color
    private let darkModeOpacity: Double
    private let lightModeOpacity: Double
    
    /// Creates a panel divider with customizable color and opacity
    /// - Parameters:
    ///   - color: The color of the divider. Defaults to black.
    ///   - darkModeOpacity: The opacity to use in dark mode. Defaults to 0.65.
    ///   - lightModeOpacity: The opacity to use in light mode. Defaults to 0.13.
    public init(
        color: Color = .black,
        darkModeOpacity: Double = 0.65,
        lightModeOpacity: Double = 0.13
    ) {
        self.color = color
        self.darkModeOpacity = darkModeOpacity
        self.lightModeOpacity = lightModeOpacity
    }

    public var body: some View {
        Divider()
            .opacity(0)
            .overlay(
                color.opacity(colorScheme == .dark ? darkModeOpacity : lightModeOpacity)
            )
    }
}

#Preview {
    VStack {
        PanelDivider()
        PanelDivider(color: .blue)
        PanelDivider(color: .red, darkModeOpacity: 0.8, lightModeOpacity: 0.3)
    }
    .frame(height: 100)
    .padding()
}
