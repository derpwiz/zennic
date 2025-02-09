import SwiftUI

/// A menu style for status bar menu items
public struct StatusBarMenuStyle: MenuStyle {
    /// The current control state
    @Environment(\.controlActiveState)
    private var controlActive
    
    /// The current color scheme
    @Environment(\.colorScheme)
    private var colorScheme
    
    public func makeBody(configuration: Configuration) -> some View {
        Menu(configuration)
            .controlSize(.small)
            .menuStyle(.borderlessButton)
            .opacity(opacity)
    }
    
    /// The opacity based on the current state
    private var opacity: Double {
        if controlActive == .inactive {
            return colorScheme == .dark ? 0.66 : 1
        } else {
            return colorScheme == .dark ? 0.54 : 0.72
        }
    }
}

public extension MenuStyle where Self == StatusBarMenuStyle {
    /// A menu style for status bar menu items
    static var statusBar: StatusBarMenuStyle { .init() }
}

/// A button style for status bar icon buttons
public struct StatusBarIconButtonStyle: ButtonStyle {
    /// Whether the button is in an active state
    let isActive: Bool
    
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(isActive ? .accentColor : .secondary)
            .brightness(configuration.isPressed ? 0.5 : 0)
    }
}

/// A view that represents an icon in the status bar
public struct StatusBarIcon: View {
    /// The icon to display
    private let icon: Image
    
    /// Whether the icon is active
    private let active: Bool
    
    /// The action to perform when clicked
    private let action: () -> Void
    
    /// The icon font size
    private let iconFont: Font
    
    /// Available icon sizes
    public enum IconSize: CGFloat {
        case small = 11
        case medium = 14.5
    }
    
    /// Creates a new status bar icon
    /// - Parameters:
    ///   - icon: The icon to display
    ///   - size: The size of the icon. Defaults to `.medium`
    ///   - active: Whether the icon is active. Defaults to `false`
    ///   - action: The action to perform when clicked
    public init(
        icon: Image,
        size: IconSize = .medium,
        active: Bool = false,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.active = active
        self.action = action
        self.iconFont = .system(size: size.rawValue, weight: .regular)
    }
    
    public var body: some View {
        Button(action: action) {
            icon
                .font(iconFont)
                .contentShape(Rectangle())
        }
        .buttonStyle(StatusBarIconButtonStyle(isActive: active))
    }
}
