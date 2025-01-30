import SwiftUI
import Shared
import Core

public struct CodeEditorView: View {
    @StateObject private var viewModel: CodeEditorViewModel
    @EnvironmentObject private var appState: AppState
    @State private var showHistory = false
    
    public init(gitService: GitService = GitService.shared) {
        let code = UserDefaults.standard.string(forKey: "currentCode") ?? ""
        let languageString = UserDefaults.standard.string(forKey: "currentLanguage") ?? CodeLanguage.python.rawValue
        let language = CodeLanguage(rawValue: languageString) ?? .python
        
        _viewModel = StateObject(wrappedValue: CodeEditorViewModel(code: code, language: language, gitService: gitService))
    }
    
    public var body: some View {
        NavigationView {
            FileTreeView()
                .environmentObject(viewModel)
                .frame(minWidth: 200, idealWidth: 250, maxWidth: 300)
            
            VStack {
                HStack {
                    HStack(spacing: 16) {
                        Button("New File") {
                            viewModel.createNewFile()
                        }
                        .help("Create a new file")
                        
                        Picker("Language", selection: $viewModel.language) {
                            ForEach(CodeLanguage.allCases, id: \.self) { lang in
                                Text(lang.rawValue).tag(lang)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .onChange(of: viewModel.language) { newLanguage in
                            appState.currentLanguage = newLanguage.rawValue
                        }
                        .help("Select the programming language for syntax highlighting")
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 8) {
                        Button("Run") {
                            runCode()
                        }
                        .keyboardShortcut(.return, modifiers: .command)
                        .help("Execute the current code (⌘↩)")
                        
                        Button("Save") {
                            saveCurrentFile()
                        }
                        .keyboardShortcut("s", modifiers: .command)
                        .help("Save changes to the current file (⌘S)")
                        
                        Button("History") {
                            showHistory.toggle()
                        }
                        .help("View and restore previous versions of the file")
                    }
                }
                .padding()
                
                CodeEditorToolbar(language: viewModel.language) { snippet in
                    insertSnippet(snippet)
                }
                
                ZStack(alignment: .topLeading) {
                    CodeEditor(text: $viewModel.code, language: viewModel.language)
                        .frame(minHeight: 300)
                        .onChange(of: viewModel.code) { newCode in
                            updateAutoCompleteSuggestions()
                            appState.currentCode = newCode
                        }
                    
                    if viewModel.showAutoComplete {
                        AutoCompleteView(suggestions: viewModel.autoCompleteSuggestions) { suggestion in
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
                    Text(viewModel.output)
                        .font(.system(.body, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(height: 150)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            }
            .padding()
            .navigationTitle(viewModel.selectedFile ?? "Untitled")
        }
        .onAppear {
            loadCodeHistory()
        }
        .sheet(isPresented: $showHistory) {
            CodeHistoryView(history: viewModel.codeHistory) { selectedVersion in
                viewModel.code = selectedVersion
                showHistory = false
            }
        }
        .alert(
            isPresented: Binding(
                get: { viewModel.error != nil },
                set: { _ in viewModel.error = nil }
            ),
            content: {
                Alert(
                    title: Text("Error"),
                    message: Text(viewModel.error?.localizedDescription ?? "Unknown error"),
                    dismissButton: .default(Text("OK"))
                )
            }
        )
    }
    
    private func runCode() {
        // Placeholder for code execution
        viewModel.output = "Code execution placeholder:\n\n\(viewModel.code)"
    }
    
    private func updateAutoCompleteSuggestions() {
        let words = viewModel.code.split(separator: "  ")
        if let lastWord = words.last, lastWord.count > 1 {
            viewModel.autoCompleteSuggestions = CodeAssistant.shared.getAutoCompleteSuggestions(for: String(lastWord), language: viewModel.language)
            viewModel.showAutoComplete = !viewModel.autoCompleteSuggestions.isEmpty
        } else {
            viewModel.showAutoComplete = false
        }
    }
    
    private func insertAutoCompleteSuggestion(_ suggestion: String) {
        let words = viewModel.code.split(separator: "  ")
        if let lastWord = words.last {
            viewModel.code = viewModel.code.replacingOccurrences(of: String(lastWord), with: suggestion, options: .backwards)
            viewModel.showAutoComplete = false
        }
    }
    
    private func insertSnippet(_ key: String) {
        if let snippet = CodeAssistant.shared.getCodeSnippet(for: key, language: viewModel.language) {
            viewModel.code.append(snippet)
        }
    }
    
    private func loadCodeHistory() {
        viewModel.codeHistory = appState.getCodeHistory(language: viewModel.language)
    }
    
    private func saveCurrentFile() {
        do {
            try viewModel.saveCurrentFile()
        } catch {
            viewModel.error = error
        }
    }
}

struct CodeHistoryView: View {
    let history: [String]
    let onSelect: (String) -> Void
    
    var body: some View {
        List(history, id: \.self) { version in
            Button(action: {
                onSelect(version)
            }) {
                Text(version)
            }
        }
        .navigationTitle("Code History")
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
            HStack(spacing: 8) {
                ForEach(CodeAssistant.shared.getSnippetKeys(for: language), id: \.self) { key in
                    Button(action: {
                        onInsertSnippet(key)
                    }) {
                        Text(key)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(4)
                            .help("Insert \(key) code snippet")
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
                    .help("Insert '\(suggestion)'")
            }
        }
        .background(Color.white)
        .border(Color.gray, width: 1)
        .cornerRadius(4)
    }
}

#Preview {
    CodeEditorView(gitService: GitService.shared)
        .environmentObject(AppState())
}
