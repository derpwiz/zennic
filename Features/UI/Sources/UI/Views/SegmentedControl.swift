import SwiftUI

/// A view that creates a segmented control from an array of text labels
public struct SegmentedControl: View {
    /// The options to display in the segmented control
    private let options: [String]
    
    /// Whether to use a prominent appearance
    private let prominent: Bool
    
    /// The currently selected index
    @Binding private var selectedIndex: Int
    
    /// Creates a new segmented control
    /// - Parameters:
    ///   - selection: Binding to the selected index
    ///   - options: Array of text labels to display
    ///   - prominent: Whether to use a prominent appearance. Defaults to `false`.
    ///               When `true`, the selected segment uses accent color with white text.
    ///               When `false`, uses a more muted selection color.
    public init(
        selection: Binding<Int>,
        options: [String],
        prominent: Bool = false
    ) {
        self._selectedIndex = selection
        self.options = options
        self.prominent = prominent
    }
    
    public var body: some View {
        HStack(spacing: 4) {
            ForEach(options.indices, id: \.self) { index in
                SegmentedControlItem(
                    label: options[index],
                    active: selectedIndex == index,
                    action: { selectedIndex = index },
                    prominent: prominent
                )
            }
        }
        .frame(height: 20)
    }
}

/// A single item in a segmented control
private struct SegmentedControlItem: View {
    /// The text label to display
    let label: String
    
    /// Whether this item is currently selected
    let active: Bool
    
    /// Action to perform when this item is selected
    let action: () -> Void
    
    /// Whether to use a prominent appearance
    let prominent: Bool
    
    /// The current color scheme
    @Environment(\.colorScheme) private var colorScheme
    
    /// The current control state
    @Environment(\.controlActiveState) private var activeState
    
    /// Whether the mouse is currently hovering over this item
    @State private var isHovering: Bool = false
    
    /// Whether this item is currently being pressed
    @State private var isPressing: Bool = false
    
    var body: some View {
        Text(label)
            .font(.subheadline)
            .foregroundColor(textColor)
            .opacity(textOpacity)
            .frame(height: 20)
            .padding(.horizontal, 7.5)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: 5))
            .onTapGesture(perform: action)
            .onHover { hover in
                isHovering = hover
            }
            .pressAction {
                isPressing = true
            } onRelease: {
                isPressing = false
            }
    }
    
    /// The text color based on the current state
    private var textColor: Color {
        if prominent {
            return active ? .white : .primary
        } else {
            return active
                ? colorScheme == .dark ? .white : .accentColor
                : .primary
        }
    }
    
    /// The text opacity based on the current state
    private var textOpacity: Double {
        if prominent {
            return activeState != .inactive ? 1 : active ? 1 : 0.3
        } else {
            return activeState != .inactive ? 1 : active ? 0.5 : 0.3
        }
    }
    
    /// The background based on the current state
    @ViewBuilder private var background: some View {
        if prominent {
            if active {
                Color.accentColor.opacity(activeState != .inactive ? 1 : 0.5)
            } else {
                Color(nsColor: colorScheme == .dark ? .white : .black)
                    .opacity(isPressing ? 0.10 : isHovering ? 0.05 : 0)
            }
        } else {
            if active {
                Color(nsColor: .selectedControlColor)
                    .opacity(isPressing ? 1 : activeState != .inactive ? 0.75 : 0.5)
            } else {
                Color(nsColor: colorScheme == .dark ? .white : .black)
                    .opacity(isPressing ? 0.10 : isHovering ? 0.05 : 0)
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        // Standard segmented control
        SegmentedControl(
            selection: .constant(0),
            options: ["One", "Two", "Three"]
        )
        
        // Prominent segmented control
        SegmentedControl(
            selection: .constant(1),
            options: ["Left", "Center", "Right"],
            prominent: true
        )
        
        // Disabled state example
        SegmentedControl(
            selection: .constant(2),
            options: ["A", "B", "C"]
        )
        .disabled(true)
    }
    .padding()
    .frame(width: 300)
}
