import SwiftUI

public struct SyntaxHighlighter {
    public static func highlight(_ code: String, language: CodeLanguage, isDarkMode: Bool) -> NSAttributedString {
        let attributedString = NSMutableAttributedString(string: code)
        // Define regex patterns and colors for different syntax elements
        let patterns: [(String, NSColor)] = [
            // Keywords
            ("\\b(def|class|import|from|if|else|elif|for|while|return|in|and|or|not|True|False|None)\\b", isDarkMode ? .cyan : .blue),
            // Strings
            ("\".*?\"|'.*?'", isDarkMode ? .green : NSColor(red: 0.0, green: 0.5, blue: 0.0, alpha: 1.0)),
            // Numbers
            ("\\b\\d+(\\.\\d+)?\\b", isDarkMode ? .orange : .brown),
            // Comments
            ("#.*", isDarkMode ? .lightGray : .darkGray)
        ]
        
        // Set default text color
        let defaultColor = isDarkMode ? NSColor.white : NSColor.black
        attributedString.addAttribute(.foregroundColor, value: defaultColor, range: NSRange(location: 0, length: code.utf16.count))
        
        for (pattern, color) in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
                let nsRange = NSRange(location: 0, length: code.utf16.count)
                regex.enumerateMatches(in: code, options: [], range: nsRange) { match, _, _ in
                    guard let match = match else { return }
                    attributedString.addAttribute(.foregroundColor, value: color, range: match.range)
                }
            }
        }
        return attributedString
    }
}

extension NSAttributedString {
    func toAttributedString() -> AttributedString {
        do {
            return try AttributedString(self, including: \.appKit)
        } catch {
            print("Error converting NSAttributedString to AttributedString: \(error)")
            return AttributedString(self.string)
        }
    }
}
