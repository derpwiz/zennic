import SwiftUI

/// A button style for status bar menu items.
public struct StatusBarMenuStyle: ButtonStyle {
    @Environment(\.colorScheme) private var colorScheme
    
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .background(
                configuration.isPressed
                ? (colorScheme == .dark ? Color.white.opacity(0.15) : Color.black.opacity(0.1))
                : Color.clear
            )
            .cornerRadius(4)
    }
}

/// A button style for status bar icon buttons.
public struct StatusBarIconStyle: ButtonStyle {
    @Environment(\.colorScheme) private var colorScheme
    let isActive: Bool
    
    public init(isActive: Bool = false) {
        self.isActive = isActive
    }
    
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(isActive ? .primary : .secondary)
            .frame(width: StatusBarIconDimensions.width, height: StatusBarIconDimensions.height)
            .contentShape(Rectangle())
            .background(
                configuration.isPressed
                ? (colorScheme == .dark ? Color.white.opacity(0.15) : Color.black.opacity(0.1))
                : Color.clear
            )
            .cornerRadius(4)
    }
}

/// A view that displays an icon in the status bar.
public struct StatusBarIcon: View {
    let systemName: String
    let isActive: Bool
    
    public init(systemName: String, isActive: Bool = false) {
        self.systemName = systemName
        self.isActive = isActive
    }
    
    public var body: some View {
        Image(systemName: systemName)
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(isActive ? .primary : .secondary)
            .frame(width: StatusBarIconDimensions.width, height: StatusBarIconDimensions.height)
            .contentShape(Rectangle())
    }
}
