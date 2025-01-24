import SwiftUI

public struct SettingsActionRow: View {
    public let title: String
    public let icon: String
    public let isDestructive: Bool
    public let action: () -> Void
    
    public init(title: String, icon: String, isDestructive: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.isDestructive = isDestructive
        self.action = action
    }
    
    public var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                Spacer()
                Image(systemName: icon)
            }
        }
        .foregroundColor(isDestructive ? .red : .accentColor)
    }
}
