import SwiftUI

/// A toolbar view for panes that appears at the bottom
public struct PaneToolbar<Content: View>: View {
    @ViewBuilder public var content: Content
    
    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    public var body: some View {
        HStack(spacing: 0) {
            content
        }
        .frame(height: 28)
        .background(.bar)
    }
}

/// A section within a pane toolbar
public struct PaneToolbarSection<Content: View>: View {
    @ViewBuilder public var content: Content
    
    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    public var body: some View {
        HStack(spacing: 0) {
            content
        }
    }
}

/// An icon button style for pane toolbars
public struct IconButtonStyle: ButtonStyle {
    public var isActive: Bool
    public var size: CGSize
    
    public init(isActive: Bool = false, size: CGSize = CGSize(width: 28, height: 28)) {
        self.isActive = isActive
        self.size = size
    }
    
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .symbolVariant(isActive ? .fill : .none)
            .frame(width: size.width, height: size.height)
            .contentShape(Rectangle())
            .foregroundColor(isActive ? .accentColor : .primary)
            .opacity(configuration.isPressed ? 0.5 : 1)
    }
}

public extension ButtonStyle where Self == IconButtonStyle {
    static func icon(isActive: Bool = false, size: CGSize = CGSize(width: 28, height: 28)) -> IconButtonStyle {
        IconButtonStyle(isActive: isActive, size: size)
    }
}
