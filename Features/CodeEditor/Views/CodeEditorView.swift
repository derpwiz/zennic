import SwiftUI

struct CodeEditorView: View {
    @State private var code: String = ""
    @State private var language: CodeLanguage = .python
    @State private var output: String = ""
    @State private var autoCompleteSuggestions: [String] = []
    @State private var showAutoComplete: Bool = false
    
    var body: some View {
        VStack {
            HStack {
                Picker("Language", selection: $language) {
                    ForEach(CodeLanguage.allCases, id: \.self) { lang in
                        Text(lang.rawValue).tag(lang)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                
                Button("Run") {
                    runCode()
                }
                .keyboardShortcut(.return, modifiers: .command)
            }
            .padding()
            
            CodeEditorToolbar(language: language) { snippet in
                insertSnippet(snippet)
            }
            
            ZStack(alignment: .topLeading) {
                CodeEditor(text: $code, language: language)
                    .frame(minHeight: 300)
                    .onChange(of: code) { _ in
                        updateAutoCompleteSuggestions()
                    }
                
                if showAutoComplete {
                    AutoCompleteView(suggestions: autoCompleteSuggestions) { suggestion in
                        insertAutoCompleteSuggestion(suggestion)
                    }
                    .offset(y: 20)
                }
            }
            
            Text("Output:")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top)
            
            ScrollView {
                Text(output)
                    .font(.system(.body, design: .monospaced))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(height: 150)
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
        }
        .padding()
    }
    
    private func runCode() {
        // Placeholder for code execution
        output = "Code execution placeholder:\n\n\(code)"
    }
    
    private func updateAutoCompleteSuggestions() {
        let words = code.split(separator: " ")
        if let lastWord = words.last, lastWord.count > 1 {
            autoCompleteSuggestions = CodeAssistant.shared.getAutoCompleteSuggestions(for: String(lastWord), language: language)
            showAutoComplete = !autoCompleteSuggestions.isEmpty
        } else {
            showAutoComplete = false
        }
    }
    
    private func insertAutoCompleteSuggestion(_ suggestion: String) {
        let words = code.split(separator: " ")
        if var lastWord = words.last {
            code = code.replacingOccurrences(of: String(lastWord), with: suggestion, options: .backwards)
            showAutoComplete = false
        }
    }
    
    private func insertSnippet(_ key: String) {
        if let snippet = CodeAssistant.shared.getCodeSnippet(for: key, language: language) {
            code.append(snippet)
        }
    }
}

struct CodeEditor: View {
    @Binding var text: String
    let language: CodeLanguage
    
    var body: some View {
        NSAttributedStringView(text: $text, language: language)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct NSAttributedStringView: NSViewRepresentable {
    @Binding var text: String
    let language: CodeLanguage
    @Environment(\.colorScheme) var colorScheme

    func makeNSView(context: Context) -> NSTextView {
        let textView = NSTextView()
        textView.isRichText = false
        textView.font = NSFont.monospacedSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
        textView.backgroundColor = .clear
        textView.drawsBackground = false
        textView.textContainer?.lineFragmentPadding = 0
        textView.textContainerInset = .zero
        textView.delegate = context.coordinator
        return textView
    }

    func updateNSView(_ nsView: NSTextView, context: Context) {
        let attributedString = SyntaxHighlighter.highlight(text, language: language, isDarkMode: colorScheme == .dark)
        nsView.textStorage?.setAttributedString(attributedString)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: NSAttributedStringView

        init(_ parent: NSAttributedStringView) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            parent.text = textView.string
        }
    }
}

struct CodeEditorToolbar: View {
    let language: CodeLanguage
    let onInsertSnippet: (String) -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(CodeAssistant.shared.getSnippetKeys(for: language), id: \.self) { key in
                    Button(action: {
                        onInsertSnippet(key)
                    }) {
                        Text(key)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(4)
                    }
                }
            }
        }
        .padding(.horizontal)
    }
}

struct AutoCompleteView: View {
    let suggestions: [String]
    let onSelect: (String) -> Void
    
    var body: some View {
        VStack(alignment: .leading) {
            ForEach(suggestions, id: \.self) { suggestion in
                Text(suggestion)
                    .padding(.vertical, 2)
                    .padding(.horizontal, 4)
                    .onTapGesture {
                        onSelect(suggestion)
                    }
            }
        }
        .background(Color.white)
        .border(Color.gray, width: 1)
    }
}

struct CodeEditorView_Previews: PreviewProvider {
    static var previews: some View {
        CodeEditorView()
    }
}
