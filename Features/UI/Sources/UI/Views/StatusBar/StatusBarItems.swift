import SwiftUI
import AppKit

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
    @Environment(\.controlActiveState) private var controlActive
    @State private var isControlPressed = false
    @State private var eventMonitor: Any?
    
    public init() {}
    
    public var body: some View {
        Text(label)
            .onAppear {
                eventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.flagsChanged]) { event in
                    isControlPressed = event.modifierFlags.contains(.control)
                    return event
                }
            }
            .onDisappear {
                if let monitor = eventMonitor {
                    NSEvent.removeMonitor(monitor)
                    eventMonitor = nil
                }
            }
            .font(statusBarViewModel.statusBarFont)
            .foregroundColor(foregroundColor)
            .lineLimit(1)
            .fixedSize()
            .accessibilityLabel("Cursor Position")
            .accessibilityAddTraits(.updatesFrequently)
    }
    
    private var foregroundColor: Color {
        if controlActive == .key {
            return Color(nsColor: .disabledControlTextColor)
        } else {
            return Color(nsColor: .secondaryLabelColor)
        }
    }
    
    private var label: String {
        statusBarViewModel.formatCursorPosition(
            showCharacterOffset: isControlPressed
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
                .symbolRenderingMode(.hierarchical)
        }
        .buttonStyle(StatusBarIconButtonStyle(isActive: false))
        .keyboardShortcut("Y", modifiers: [.command, .shift])
        .help(utilityAreaViewModel.isCollapsed ? "Show the Utility area" : "Hide the Utility area")
    }
}

/// A menu for selecting the indentation settings
public struct StatusBarIndentSelector: View {
    @AppStorage("useTabs") private var useTabs = false
    @AppStorage("tabWidth") private var tabWidth: Int = 4
    
    public init() {}
    
    public var body: some View {
        Menu {
            Button {
                useTabs = true
            } label: {
                HStack {
                    Text("Use Tabs")
                    if useTabs {
                        Image(systemName: "checkmark")
                    }
                }
            }
            
            Button {
                useTabs = false
            } label: {
                HStack {
                    Text("Use Spaces")
                    if !useTabs {
                        Image(systemName: "checkmark")
                    }
                }
            }
            
            Divider()
            
            Picker("Tab Width", selection: $tabWidth) {
                ForEach(2..<9) { index in
                    Text("\(index) \(useTabs ? "Tabs" : "Spaces")")
                        .tag(index)
                }
            }
        } label: {
            Text("\(tabWidth) \(useTabs ? "Tabs" : "Spaces")")
                .font(.system(size: 11))
        }
        .menuStyle(.statusBar)
    }
}

/// A menu for selecting the text encoding
public struct StatusBarEncodingSelector: View {
    @AppStorage("fileEncoding") private var fileEncoding = "UTF-8"
    
    public init() {}
    
    public var body: some View {
        Menu {
            ForEach(["UTF-8", "UTF-16", "ASCII", "ISO-8859-1"], id: \.self) { encoding in
                Button {
                    fileEncoding = encoding
                } label: {
                    HStack {
                        Text(encoding)
                        if encoding == fileEncoding {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            Text(fileEncoding)
                .font(.system(size: 11))
        }
        .menuStyle(.statusBar)
    }
}

/// A menu for selecting the line ending style
public struct StatusBarLineEndSelector: View {
    @AppStorage("lineEnding") private var lineEnding = "LF"
    
    public init() {}
    
    public var body: some View {
        Menu {
            ForEach(["LF", "CRLF", "CR"], id: \.self) { ending in
                Button {
                    lineEnding = ending
                } label: {
                    HStack {
                        Text(ending)
                        if ending == lineEnding {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            Text(lineEnding)
                .font(.system(size: 11))
        }
        .menuStyle(.statusBar)
    }
}
