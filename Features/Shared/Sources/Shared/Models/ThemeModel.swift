import SwiftUI
import Combine

/// Manages themes for the application
public class ThemeModel: ObservableObject {
    /// Shared instance
    public static let shared = ThemeModel()
    
    /// Currently selected theme
    @Published public var selectedTheme: Theme?
    
    /// Available themes
    @Published public var themes: [Theme] = [
        .darkDefault,
        .lightDefault
    ]
    
    /// Current appearance (light/dark)
    @Published public var appearance: ColorScheme = .dark
    
    private init() {
        selectedTheme = themes.first { $0.appearance == appearance }
    }
    
    /// Updates the current theme based on appearance
    /// - Parameter appearance: The new appearance
    public func updateTheme(for appearance: ColorScheme) {
        self.appearance = appearance
        if selectedTheme?.appearance != appearance {
            selectedTheme = themes.first { $0.appearance == appearance }
        }
    }
    
    /// Adds a new theme
    /// - Parameter theme: The theme to add
    public func addTheme(_ theme: Theme) {
        themes.append(theme)
    }
    
    /// Removes a theme
    /// - Parameter theme: The theme to remove
    public func removeTheme(_ theme: Theme) {
        themes.removeAll { $0.name == theme.name }
    }
    
    /// Updates a theme
    /// - Parameters:
    ///   - theme: The theme to update
    ///   - newTheme: The new theme data
    public func updateTheme(_ theme: Theme, with newTheme: Theme) {
        if let index = themes.firstIndex(where: { $0.name == theme.name }) {
            themes[index] = newTheme
            if selectedTheme?.name == theme.name {
                selectedTheme = newTheme
            }
        }
    }
}
