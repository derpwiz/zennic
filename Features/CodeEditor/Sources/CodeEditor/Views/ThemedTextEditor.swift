import SwiftUI
import Shared

struct ThemedTextEditor: NSViewRepresentable {
    @Binding var text: String
    let theme: Theme
    let isEditable: Bool
    
    func makeNSView(context: Context) -> NSScrollView {
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
        lineNumberView.backgroundColor = NSColor(theme.editor.background)
        lineNumberView.textColor = NSColor(theme.editor.lineNumber)
        scrollView.verticalRulerView = lineNumberView
        scrollView.hasVerticalRuler = true
        scrollView.rulersVisible = true
        
        return scrollView
    }
    
    func updateNSView(_ scrollView: NSScrollView, context: Context) {
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
            lineNumberView.backgroundColor = NSColor(theme.editor.background)
            lineNumberView.textColor = NSColor(theme.editor.lineNumber)
            lineNumberView.needsDisplay = true
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }
    
    class Coordinator: NSObject, NSTextViewDelegate {
        var text: Binding<String>
        
        init(text: Binding<String>) {
            self.text = text
        }
        
        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            text.wrappedValue = textView.string
        }
    }
}

class LineNumberRulerView: NSRulerView {
    var textColor: NSColor = .secondaryLabelColor
    
    init(textView: NSTextView) {
        super.init(scrollView: textView.enclosingScrollView!, orientation: .verticalRuler)
        self.clientView = textView
        self.ruleThickness = 40
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func drawHashMarksAndLabels(in rect: NSRect) {
        guard let textView = clientView as? NSTextView,
              let layoutManager = textView.layoutManager,
              let container = textView.textContainer else { return }
        
        let visibleRect = textView.visibleRect
        let glyphRange = layoutManager.glyphRange(forBoundingRect: visibleRect, in: container)
        let characterRange = layoutManager.characterRange(forGlyphRange: glyphRange, actualGlyphRange: nil)
        
        let content = textView.string as NSString
        content.enumerateSubstrings(in: characterRange, options: [.byLines, .substringNotRequired]) { _, substringRange, _, _ in
            let lineNumber = content.substring(with: NSRange(location: 0, length: substringRange.location))
                .components(separatedBy: .newlines)
                .count
            
            let glyphIndex = layoutManager.glyphIndex(for: substringRange.location)
            var lineRect = layoutManager.boundingRect(forGlyphRange: NSRange(location: glyphIndex, length: 1), in: container)
            lineRect.origin.y -= textView.textContainerInset.height
            
            let attrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.monospacedDigitSystemFont(ofSize: NSFont.systemFontSize - 1, weight: .regular),
                .foregroundColor: textColor
            ]
            
            let attributedString = NSAttributedString(string: "\(lineNumber)", attributes: attrs)
            let stringSize = attributedString.size()
            
            let point = NSPoint(
                x: ruleThickness - stringSize.width - 4,
                y: lineRect.minY + (lineRect.height - stringSize.height) / 2
            )
            attributedString.draw(at: point)
        }
    }
}
