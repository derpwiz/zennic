import SwiftUI
import Shared

public struct ThemedTextEditor: NSViewRepresentable {
    @Binding public var text: String
    public let theme: Theme
    public let isEditable: Bool
    public let onCursorChange: ((Int, Int, Int) -> Void)?
    public let onSelectionChange: ((Int, Int) -> Void)?
    
    public init(
        text: Binding<String>,
        theme: Theme,
        isEditable: Bool,
        onCursorChange: ((Int, Int, Int) -> Void)? = nil,
        onSelectionChange: ((Int, Int) -> Void)? = nil
    ) {
        self._text = text
        self.theme = theme
        self.isEditable = isEditable
        self.onCursorChange = onCursorChange
        self.onSelectionChange = onSelectionChange
    }
    
    public func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        let textView = scrollView.documentView as! NSTextView
        
        // Configure text view
        textView.isEditable = isEditable
        textView.isRichText = false
        textView.font = .monospacedSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
        textView.delegate = context.coordinator
        
        // Apply theme
        textView.backgroundColor = NSColor(theme.editor.background)
        textView.textColor = NSColor(theme.editor.text)
        textView.insertionPointColor = NSColor(theme.editor.text)
        
        // Configure selection colors
        textView.selectedTextAttributes = [
            .backgroundColor: NSColor(theme.editor.selection),
            .foregroundColor: NSColor(theme.editor.text)
        ]
        
        // Add line numbers
        let lineNumberView = LineNumberRulerView(textView: textView)
        lineNumberView.setBackgroundColor(NSColor(theme.editor.background))
        lineNumberView.textColor = NSColor(theme.editor.lineNumber)
        scrollView.verticalRulerView = lineNumberView
        scrollView.hasVerticalRuler = true
        scrollView.rulersVisible = true
        
        // Enable cursor position notifications
        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.textViewDidChangeSelection(_:)),
            name: NSTextView.didChangeSelectionNotification,
            object: textView
        )
        
        return scrollView
    }
    
    public func updateNSView(_ scrollView: NSScrollView, context: Context) {
        let textView = scrollView.documentView as! NSTextView
        
        // Only update text if it's different to avoid cursor jumping
        if textView.string != text {
            textView.string = text
        }
        
        // Update theme colors
        textView.backgroundColor = NSColor(theme.editor.background)
        textView.textColor = NSColor(theme.editor.text)
        textView.insertionPointColor = NSColor(theme.editor.text)
        textView.selectedTextAttributes = [
            .backgroundColor: NSColor(theme.editor.selection),
            .foregroundColor: NSColor(theme.editor.text)
        ]
        
        if let lineNumberView = scrollView.verticalRulerView as? LineNumberRulerView {
            lineNumberView.setBackgroundColor(NSColor(theme.editor.background))
            lineNumberView.textColor = NSColor(theme.editor.lineNumber)
            lineNumberView.needsDisplay = true
        }
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(
            text: $text,
            onCursorChange: onCursorChange,
            onSelectionChange: onSelectionChange
        )
    }
    
    public class Coordinator: NSObject, NSTextViewDelegate {
        var text: Binding<String>
        var onCursorChange: ((Int, Int, Int) -> Void)?
        var onSelectionChange: ((Int, Int) -> Void)?
        
        init(
            text: Binding<String>,
            onCursorChange: ((Int, Int, Int) -> Void)?,
            onSelectionChange: ((Int, Int) -> Void)?
        ) {
            self.text = text
            self.onCursorChange = onCursorChange
            self.onSelectionChange = onSelectionChange
        }
        
        public func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            text.wrappedValue = textView.string
            updateCursorInfo(for: textView)
        }
        
        @objc func textViewDidChangeSelection(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            updateCursorInfo(for: textView)
        }
        
        private func updateCursorInfo(for textView: NSTextView) {
            let selectedRange = textView.selectedRange()
            let content = textView.string
            
            // Calculate line and column
            let start = content.startIndex
            let cursorIndex = content.index(start, offsetBy: selectedRange.location)
            let lineRange = content.lineRange(for: ...cursorIndex)
            let line = content[..<cursorIndex].components(separatedBy: .newlines).count
            let column = content.distance(from: lineRange.lowerBound, to: cursorIndex) + 1
            
            // Report cursor position
            onCursorChange?(line, column, selectedRange.location)
            
            // Report selection if any
            if selectedRange.length > 0 {
                let selectedText = content[
                    content.index(start, offsetBy: selectedRange.location)..<
                    content.index(start, offsetBy: selectedRange.location + selectedRange.length)
                ]
                let selectedLines = selectedText.components(separatedBy: .newlines).count
                onSelectionChange?(selectedRange.length, selectedLines)
            } else {
                onSelectionChange?(0, 0)
            }
        }
    }
}

class LineNumberRulerView: NSRulerView {
    var textColor: NSColor = .secondaryLabelColor
    private var _backgroundColor: NSColor = .clear
    
    init(textView: NSTextView) {
        super.init(scrollView: textView.enclosingScrollView!, orientation: .verticalRuler)
        self.clientView = textView
        self.ruleThickness = 40
    }
    
    override func draw(_ dirtyRect: NSRect) {
        // Fill background
        _backgroundColor.setFill()
        dirtyRect.fill()
        super.draw(dirtyRect)
    }
    
    func setBackgroundColor(_ color: NSColor) {
        _backgroundColor = color
        needsDisplay = true
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func drawHashMarksAndLabels(in rect: NSRect) {
        super.drawHashMarksAndLabels(in: rect)
        
        guard let textView = clientView as? NSTextView,
              let layoutManager = textView.layoutManager,
              let container = textView.textContainer else { return }
        
        let visibleRect = textView.visibleRect
        let glyphRange = layoutManager.glyphRange(forBoundingRect: visibleRect, in: container)
        let characterRange = layoutManager.characterRange(forGlyphRange: glyphRange, actualGlyphRange: nil)
        
        let content = textView.string as NSString
        content.enumerateSubstrings(in: characterRange, options: [.byLines, .substringNotRequired]) { [self] _, substringRange, _, _ in
            let lineNumber = content.substring(with: NSRange(location: 0, length: substringRange.location))
                .components(separatedBy: .newlines)
                .count
            
            let characterIndex = substringRange.location
            let glyphRange = layoutManager.glyphRange(forCharacterRange: NSRange(location: characterIndex, length: 1), actualCharacterRange: nil)
            var lineRect = layoutManager.boundingRect(forGlyphRange: glyphRange, in: container)
            lineRect.origin.y -= textView.textContainerInset.height
            
            let attrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.monospacedDigitSystemFont(ofSize: NSFont.systemFontSize - 1, weight: .regular),
                .foregroundColor: textColor
            ]
            
            let attributedString = NSAttributedString(string: "\(lineNumber)", attributes: attrs)
            let stringSize = attributedString.size()
            
            let drawRect = NSRect(
                x: ruleThickness - stringSize.width - 4,
                y: lineRect.minY + (lineRect.height - stringSize.height) / 2,
                width: stringSize.width,
                height: stringSize.height
            )
            attributedString.draw(with: drawRect, options: [.usesLineFragmentOrigin])
        }
    }
}
