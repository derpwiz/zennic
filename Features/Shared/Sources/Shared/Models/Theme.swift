import SwiftUI

/// A theme that defines colors and styles for the editor
public struct Theme: Codable, Equatable {
    /// Editor-specific theme settings
    public struct Editor: Codable, Equatable {
        /// Text colors
        public var text: Color
        /// Background color
        public var background: Color
        /// Line number colors
        public var lineNumber: Color
        /// Current line highlight color
        public var lineHighlight: Color
        /// Selection background color
        public var selection: Color
        
        public init(
            text: Color = .primary,
            background: Color = .clear,
            lineNumber: Color = .secondary,
            lineHighlight: Color = Color(.sRGB, red: 0, green: 0, blue: 0, opacity: 0.05),
            selection: Color = Color(.sRGB, red: 0.3, green: 0.5, blue: 0.8, opacity: 0.3)
        ) {
            self.text = text
            self.background = background
            self.lineNumber = lineNumber
            self.lineHighlight = lineHighlight
            self.selection = selection
        }
    }
    
    /// The theme's name
    public var name: String
    /// The theme's appearance (light/dark)
    public var appearance: ColorScheme
    /// Editor-specific theme settings
    public var editor: Editor
    
    public init(
        name: String,
        appearance: ColorScheme = .dark,
        editor: Editor = Editor()
    ) {
        self.name = name
        self.appearance = appearance
        self.editor = editor
    }
    
    /// Default dark theme
    public static let darkDefault = Theme(
        name: "Dark",
        appearance: .dark,
        editor: Editor(
            text: Color(.sRGB, red: 0.9, green: 0.9, blue: 0.9, opacity: 1),
            background: Color(.sRGB, red: 0.12, green: 0.12, blue: 0.12, opacity: 1),
            lineNumber: Color(.sRGB, red: 0.5, green: 0.5, blue: 0.5, opacity: 1),
            lineHighlight: Color(.sRGB, red: 1, green: 1, blue: 1, opacity: 0.05),
            selection: Color(.sRGB, red: 0.3, green: 0.5, blue: 0.8, opacity: 0.3)
        )
    )
    
    /// Default light theme
    public static let lightDefault = Theme(
        name: "Light",
        appearance: .light,
        editor: Editor(
            text: Color(.sRGB, red: 0.1, green: 0.1, blue: 0.1, opacity: 1),
            background: Color(.sRGB, red: 1, green: 1, blue: 1, opacity: 1),
            lineNumber: Color(.sRGB, red: 0.5, green: 0.5, blue: 0.5, opacity: 1),
            lineHighlight: Color(.sRGB, red: 0, green: 0, blue: 0, opacity: 0.05),
            selection: Color(.sRGB, red: 0.3, green: 0.5, blue: 0.8, opacity: 0.3)
        )
    )
}

extension Color: Codable {
    enum CodingKeys: String, CodingKey {
        case red, green, blue, alpha
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let red = try container.decode(Double.self, forKey: .red)
        let green = try container.decode(Double.self, forKey: .green)
        let blue = try container.decode(Double.self, forKey: .blue)
        let alpha = try container.decode(Double.self, forKey: .alpha)
        self.init(.sRGB, red: red, green: green, blue: blue, opacity: alpha)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        NSColor(self).getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        try container.encode(red, forKey: .red)
        try container.encode(green, forKey: .green)
        try container.encode(blue, forKey: .blue)
        try container.encode(alpha, forKey: .alpha)
    }
}
