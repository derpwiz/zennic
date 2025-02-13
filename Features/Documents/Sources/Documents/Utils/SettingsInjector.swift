//
//  SettingsInjector.swift
//  zennic
//

import SwiftUI

/// A view modifier that injects app settings into the environment
struct SettingsInjector<Content: View>: View {
    @StateObject private var settings = AppSettings.shared
    let content: () -> Content
    
    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }
    
    var body: some View {
        content()
            .environmentObject(settings)
    }
}

/// A class to manage application-wide settings
final class AppSettings: ObservableObject {
    static let shared = AppSettings()
    
    // MARK: - General Settings
    
    @AppStorage("appearance") var appearance: Appearance = .system
    @AppStorage("showInvisibleCharacters") var showInvisibleCharacters = false
    @AppStorage("showLineNumbers") var showLineNumbers = true
    @AppStorage("showMinimap") var showMinimap = true
    @AppStorage("fontFamily") var fontFamily = "SF Mono"
    @AppStorage("fontSize") var fontSize: Double = 12
    
    // MARK: - Editor Settings
    
    @AppStorage("tabWidth") var tabWidth = 4
    @AppStorage("insertSpaces") var insertSpaces = true
    @AppStorage("trimWhitespace") var trimWhitespace = true
    @AppStorage("addNewline") var addNewline = true
    
    // MARK: - Theme Settings
    
    @AppStorage("theme") var theme = "Default"
    @AppStorage("syntaxHighlighting") var syntaxHighlighting = true
    
    // MARK: - Terminal Settings
    
    @AppStorage("terminalFontFamily") var terminalFontFamily = "SF Mono"
    @AppStorage("terminalFontSize") var terminalFontSize: Double = 12
    @AppStorage("terminalOpacity") var terminalOpacity: Double = 1.0
    
    private init() {}
}

// MARK: - Supporting Types

enum Appearance: String {
    case system
    case light
    case dark
}

// MARK: - AppStorage Property Wrapper

@propertyWrapper
struct AppStorage<Value> {
    private let key: String
    private let defaultValue: Value
    private let storage: UserDefaults
    
    var wrappedValue: Value {
        get {
            let value = storage.object(forKey: key) as? Value
            return value ?? defaultValue
        }
        set {
            if let optional = newValue as? AnyOptional, optional.isNil {
                storage.removeObject(forKey: key)
            } else {
                storage.set(newValue, forKey: key)
            }
        }
    }
    
    init(wrappedValue: Value,
         _ key: String,
         store: UserDefaults = .standard) {
        self.defaultValue = wrappedValue
        self.key = key
        self.storage = store
    }
}

// MARK: - Optional Protocol

private protocol AnyOptional {
    var isNil: Bool { get }
}

extension Optional: AnyOptional {
    var isNil: Bool { self == nil }
}
