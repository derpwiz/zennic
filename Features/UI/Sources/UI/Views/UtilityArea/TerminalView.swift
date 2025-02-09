import SwiftUI

/// A view that provides terminal functionality in the utility area
public struct TerminalView: NSViewRepresentable {
    /// The current working directory
    private let workingDirectory: String
    
    /// The terminal view model
    @StateObject private var viewModel = TerminalViewModel()
    
    /// Creates a new terminal view
    /// - Parameter workingDirectory: The working directory for the terminal
    public init(workingDirectory: String) {
        self.workingDirectory = workingDirectory
    }
    
    public func makeNSView(context: Context) -> NSView {
        let terminalView = NSView()
        
        // Create terminal process
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-l"] // Login shell
        process.currentDirectoryURL = URL(fileURLWithPath: workingDirectory)
        
        // Create pipes for I/O
        let masterFD = posix_openpt(O_RDWR | O_NOCTTY)
        guard masterFD >= 0 else { return terminalView }
        
        guard grantpt(masterFD) == 0,
              unlockpt(masterFD) == 0,
              let slavePath = String(cString: ptsname(masterFD)) else {
            close(masterFD)
            return terminalView
        }
        
        let slaveFD = open(slavePath, O_RDWR)
        guard slaveFD >= 0 else {
            close(masterFD)
            return terminalView
        }
        
        // Set up terminal attributes
        var termios = termios()
        tcgetattr(slaveFD, &termios)
        cfmakeraw(&termios)
        tcsetattr(slaveFD, TCSANOW, &termios)
        
        // Redirect process I/O to slave PTY
        process.standardInput = FileHandle(fileDescriptor: slaveFD)
        process.standardOutput = FileHandle(fileDescriptor: slaveFD)
        process.standardError = FileHandle(fileDescriptor: slaveFD)
        
        // Create terminal emulator view
        let terminal = NSTextView(frame: terminalView.bounds)
        terminal.isEditable = true
        terminal.isRichText = false
        terminal.font = .monospacedSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
        terminal.backgroundColor = .black
        terminal.textColor = .white
        terminal.delegate = context.coordinator
        
        // Set up terminal view
        let scrollView = NSScrollView(frame: terminalView.bounds)
        scrollView.documentView = terminal
        scrollView.hasVerticalScroller = true
        scrollView.autoresizingMask = [.width, .height]
        terminalView.addSubview(scrollView)
        
        // Start reading from master PTY
        let masterHandle = FileHandle(fileDescriptor: masterFD)
        masterHandle.readabilityHandler = { handle in
            let data = handle.availableData
            guard !data.isEmpty else {
                handle.readabilityHandler = nil
                return
            }
            
            if let output = String(data: data, encoding: .utf8) {
                DispatchQueue.main.async {
                    terminal.string += output
                    terminal.scrollToEndOfDocument(nil)
                }
            }
        }
        
        // Store state
        context.coordinator.terminal = terminal
        context.coordinator.masterHandle = masterHandle
        context.coordinator.process = process
        
        // Start process
        try? process.run()
        
        return terminalView
    }
    
    public func updateNSView(_ nsView: NSView, context: Context) {
        // Handle updates if needed
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(viewModel: viewModel)
    }
    
    public class Coordinator: NSObject, NSTextViewDelegate {
        var viewModel: TerminalViewModel
        var terminal: NSTextView?
        var masterHandle: FileHandle?
        var process: Process?
        
        init(viewModel: TerminalViewModel) {
            self.viewModel = viewModel
        }
        
        public func textView(_ textView: NSTextView, shouldChangeTextIn affectedCharRange: NSRange, replacementString: String?) -> Bool {
            // Only allow input at the end
            let lastRange = NSRange(location: textView.string.count, length: 0)
            guard affectedCharRange.location >= lastRange.location else {
                return false
            }
            
            // Send input to terminal
            if let input = replacementString?.data(using: .utf8) {
                masterHandle?.write(input)
            }
            
            return true
        }
        
        deinit {
            // Clean up
            process?.terminate()
            masterHandle?.readabilityHandler = nil
            try? masterHandle?.close()
        }
    }
}

/// View model for the terminal
class TerminalViewModel: ObservableObject {
    /// The current command being typed
    @Published var currentCommand: String = ""
    
    /// The command history
    @Published var history: [String] = []
    
    /// Adds a command to the history
    /// - Parameter command: The command to add
    func addToHistory(_ command: String) {
        history.append(command)
    }
}
