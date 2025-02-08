import SwiftUI
import Combine

/// Manages themes for the application
public class ThemeModel: ObservableObject {
    private enum Keys {
        static let selectedTheme = "selectedTheme"
        static let customThemes = "customThemes"
    }
    
    /// Shared instance
    public static let shared = ThemeModel()
    
    /// Currently selected theme
    @Published public var selectedTheme: Theme? {
        didSet {
            if let theme = selectedTheme {
                saveSelectedTheme(theme)
            }
        }
    }
    
    /// Available themes
    @Published public var themes: [Theme] = [
        .darkDefault,
        .lightDefault
    ] {
        didSet {
            saveCustomThemes()
        }
    }
    
    /// Current appearance (light/dark)
    @Published public var appearance: ColorScheme = .dark
    
    private init() {
        loadThemes()
        selectedTheme = loadSelectedTheme() ?? themes.first { $0.appearance == appearance }
    }
    
    private func saveSelectedTheme(_ theme: Theme) {
        if let data = try? JSONEncoder().encode(theme) {
            UserDefaults.standard.set(data, forKey: Keys.selectedTheme)
        }
    }
    
    private func loadSelectedTheme() -> Theme? {
        guard let data = UserDefaults.standard.data(forKey: Keys.selectedTheme),
              let theme = try? JSONDecoder().decode(Theme.self, from: data) else {
            return nil
        }
        return theme
    }
    
    private func saveCustomThemes() {
        // Only save non-default themes
        let customThemes = themes.filter { theme in
            theme.name != Theme.darkDefault.name && theme.name != Theme.lightDefault.name
        }
        if let data = try? JSONEncoder().encode(customThemes) {
            UserDefaults.standard.set(data, forKey: Keys.customThemes)
        }
    }
    
    private func loadThemes() {
        // Start with default themes
        var loadedThemes = [Theme.darkDefault, Theme.lightDefault]
        
        // Add any saved custom themes
        if let data = UserDefaults.standard.data(forKey: Keys.customThemes),
           let customThemes = try? JSONDecoder().decode([Theme].self, from: data) {
            loadedThemes.append(contentsOf: customThemes)
        }
        
        themes = loadedThemes
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
