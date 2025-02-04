import Foundation

public class SettingsManager {
    public static let shared = SettingsManager()
    private let defaults = UserDefaults.standard
    
    private init() {
        // Create application support directory if needed
        try? FileManager.default.createDirectory(at: applicationSupportURL, 
                                               withIntermediateDirectories: true)
    }
    
    // MARK: - Keys
    private enum Keys {
        static let isDarkMode = "zennic.settings.isDarkMode"
        // Add more settings keys here as needed
    }
    
    // MARK: - Settings Properties
    
    public var isDarkMode: Bool {
        get { defaults.bool(forKey: Keys.isDarkMode) }
        set {
            let oldValue = defaults.bool(forKey: Keys.isDarkMode)
            if oldValue != newValue {
                defaults.set(newValue, forKey: Keys.isDarkMode)
                NotificationCenter.default.post(name: .settingsChanged, object: nil)
            }
        }
    }
    
    // MARK: - File Management
    
    private lazy var applicationSupportURL: URL = {
        FileManager.default.urls(for: .applicationSupportDirectory, 
                               in: .userDomainMask)[0]
            .appendingPathComponent("Zennic")
    }()
}

// MARK: - Notifications

public extension Notification.Name {
    static let settingsChanged = Notification.Name("zennic.settingsChanged")
}
