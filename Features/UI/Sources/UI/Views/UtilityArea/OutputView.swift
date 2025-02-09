import SwiftUI

/// A view that displays text-based output in the utility area
public struct OutputView: NSViewRepresentable {
    /// The output text
    @Binding private var text: String
    
    /// Whether the view should auto-scroll to the bottom
    private let autoScroll: Bool
    
    /// Creates a new output view
    /// - Parameters:
    ///   - text: The output text to display
    ///   - autoScroll: Whether to auto-scroll to the bottom
    public init(text: Binding<String>, autoScroll: Bool = true) {
        self._text = text
        self.autoScroll = autoScroll
    }
    
    public func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        let textView = scrollView.documentView as! NSTextView
        
        // Configure text view
        textView.isEditable = false
        textView.isRichText = false
        textView.font = .monospacedSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
        textView.backgroundColor = .black
        textView.textColor = .white
        textView.string = text
        
        // Enable auto-scrolling if needed
        if autoScroll {
            textView.enclosingScrollView?.hasVerticalScroller = true
            textView.textContainer?.widthTracksTextView = true
            
            // Scroll to bottom when text changes
            NotificationCenter.default.addObserver(
                forName: NSText.didChangeNotification,
                object: textView,
                queue: .main
            ) { _ in
                textView.scrollToEndOfDocument(nil)
            }
        }
        
        return scrollView
    }
    
    public func updateNSView(_ scrollView: NSScrollView, context: Context) {
        let textView = scrollView.documentView as! NSTextView
        
        // Only update if text has changed
        if textView.string != text {
            textView.string = text
            if autoScroll {
                textView.scrollToEndOfDocument(nil)
            }
        }
    }
}

/// A view model for the output view
public class OutputViewModel: ObservableObject {
    /// The current output text
    @Published public var text: String = ""
    
    /// The maximum number of lines to keep
    private let maxLines: Int
    
    /// Creates a new output view model
    /// - Parameter maxLines: The maximum number of lines to keep (default: 10000)
    public init(maxLines: Int = 10000) {
        self.maxLines = maxLines
    }
    
    /// Appends text to the output
    /// - Parameter text: The text to append
    public func append(_ text: String) {
        DispatchQueue.main.async {
            self.text += text
            
            // Trim old lines if needed
            let lines = self.text.components(separatedBy: .newlines)
            if lines.count > self.maxLines {
                self.text = lines.suffix(self.maxLines).joined(separator: "\n")
            }
        }
    }
    
    /// Clears the output
    public func clear() {
        DispatchQueue.main.async {
            self.text = ""
        }
    }
}
