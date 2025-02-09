import SwiftUI

/// A divider for the status bar
public struct StatusBarDivider: View {
    public init() {}
    
    public var body: some View {
        Divider()
            .frame(maxHeight: 12)
    }
}

/// Shows file information in the status bar
public struct StatusBarFileInfoView: View {
    @EnvironmentObject private var statusBarViewModel: StatusBarViewModel
    
    private let dimensionsNumberStyle = IntegerFormatStyle<Int>()
        .locale(Locale(identifier: "en_US"))
        .grouping(.never)
    
    public init() {}
    
    public var body: some View {
        HStack(spacing: 15) {
            if let dimensions = statusBarViewModel.model.dimensions {
                let width = dimensionsNumberStyle.format(dimensions.width)
                let height = dimensionsNumberStyle.format(dimensions.height)
                Text("\(width) × \(height)")
            }
            
            if let fileSize = statusBarViewModel.model.fileSize {
                Text(fileSize.formatted(.byteCount(style: .memory)))
            }
        }
        .font(statusBarViewModel.statusBarFont)
        .foregroundStyle(statusBarViewModel.foregroundStyle)
    }
}

/// Shows cursor position information in the status bar
public struct StatusBarCursorPositionView: View {
    @EnvironmentObject private var statusBarViewModel: StatusBarViewModel
    @Environment(\.modifierKeys) private var modifierKeys
    @Environment(\.controlActiveState) private var controlActive
    
    public init() {}
    
    public var body: some View {
        Text(label)
            .font(statusBarViewModel.statusBarFont)
            .foregroundColor(foregroundColor)
            .lineLimit(1)
            .fixedSize()
            .accessibilityLabel("Cursor Position")
            .accessibilityAddTraits(.updatesFrequently)
    }
    
    private var foregroundColor: Color {
        if controlActive == .inactive {
            return Color(nsColor: .disabledControlTextColor)
        } else {
            return Color(nsColor: .secondaryLabelColor)
        }
    }
    
    private var label: String {
        statusBarViewModel.formatCursorPosition(
            showCharacterOffset: modifierKeys.contains(.option)
        )
    }
}

/// A button to toggle the utility area
public struct StatusBarToggleUtilityAreaButton: View {
    @Environment(\.controlActiveState) private var controlActive
    @EnvironmentObject private var utilityAreaViewModel: UtilityAreaViewModel
    
    public init() {}
    
    public var body: some View {
        Button {
            utilityAreaViewModel.togglePanel()
        } label: {
            Image(systemName: "square.bottomthird.inset.filled")
        }
        .buttonStyle(.icon)
        .keyboardShortcut("Y", modifiers: [.command, .shift])
        .help(utilityAreaViewModel.isCollapsed ? "Show the Utility area" : "Hide the Utility area")
    }
}

/// A menu for selecting the indentation settings
public struct StatusBarIndentSelector: View {
    @AppStorage("defaultTabWidth") private var defaultTabWidth: Int = 4
    
    public init() {}
    
    public var body: some View {
        Menu {
            Button {
                // TODO: Implement tab/space switching
            } label: {
                Text("Use Tabs")
            }
            .disabled(true)
            
            Button {
                // TODO: Implement tab/space switching
            } label: {
                Text("Use Spaces")
            }
            .disabled(true)
            
            Divider()
            
            Picker("Tab Width", selection: $defaultTabWidth) {
                ForEach(2..<9) { index in
                    Text("\(index) Spaces")
                        .tag(index)
                }
            }
        } label: {
            Text("\(defaultTabWidth) Spaces")
        }
        .menuStyle(.statusBar)
    }
}

/// A menu for selecting the text encoding
public struct StatusBarEncodingSelector: View {
    public init() {}
    
    public var body: some View {
        Menu {
            // TODO: Add encoding options
        } label: {
            Text("UTF-8")
        }
        .menuStyle(.statusBar)
    }
}

/// A menu for selecting the line ending style
public struct StatusBarLineEndSelector: View {
    public init() {}
    
    public var body: some View {
        Menu {
            // TODO: Add line ending options
        } label: {
            Text("LF")
        }
        .menuStyle(.statusBar)
    }
}
