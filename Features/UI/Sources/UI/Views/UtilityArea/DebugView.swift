import SwiftUI

/// A view that displays debugging information in the utility area
public struct DebugView: View {
    /// The debug view model
    @StateObject private var viewModel = DebugViewModel()
    
    /// Creates a new debug view
    public init() {}
    
    public var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack {
                // Level filter
                Picker("Log Level", selection: $viewModel.selectedLevel) {
                    ForEach(LogLevel.allCases, id: \.self) { level in
                        Text(level.rawValue)
                            .tag(level)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 300)
                
                Spacer()
                
                // Clear button
                Button {
                    viewModel.clear()
                } label: {
                    Image(systemName: "trash")
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            }
            .padding(.horizontal)
            .frame(height: 29)
            .background(EffectView(.contentBackground))
            
            // Log output
            OutputView(text: $viewModel.filteredText)
        }
    }
}

/// The log level for debug messages
public enum LogLevel: String, CaseIterable {
    case all = "All"
    case info = "Info"
    case warning = "Warning"
    case error = "Error"
}

/// A debug message with metadata
public struct DebugMessage: Identifiable {
    /// The unique identifier
    public let id = UUID()
    
    /// The message text
    public let text: String
    
    /// The log level
    public let level: LogLevel
    
    /// The timestamp
    public let timestamp: Date
    
    /// Creates a new debug message
    /// - Parameters:
    ///   - text: The message text
    ///   - level: The log level
    ///   - timestamp: The timestamp (default: now)
    public init(text: String, level: LogLevel, timestamp: Date = Date()) {
        self.text = text
        self.level = level
        self.timestamp = timestamp
    }
    
    /// The formatted message text
    public var formattedText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return "[\(formatter.string(from: timestamp))] [\(level.rawValue.uppercased())] \(text)"
    }
}

/// View model for the debug view
public class DebugViewModel: ObservableObject {
    /// The selected log level filter
    @Published public var selectedLevel: LogLevel = .all
    
    /// The debug messages
    @Published private var messages: [DebugMessage] = []
    
    /// The filtered text based on the selected level
    public var filteredText: String {
        get {
            messages
                .filter { selectedLevel == .all || $0.level == selectedLevel }
                .map(\.formattedText)
                .joined(separator: "\n")
        }
        set {}
    }
    
    /// Adds a debug message
    /// - Parameters:
    ///   - text: The message text
    ///   - level: The log level
    public func log(_ text: String, level: LogLevel) {
        DispatchQueue.main.async {
            self.messages.append(DebugMessage(text: text, level: level))
        }
    }
    
    /// Clears all messages
    public func clear() {
        DispatchQueue.main.async {
            self.messages.removeAll()
        }
    }
}

#Preview {
    DebugView()
        .frame(width: 800, height: 400)
}
