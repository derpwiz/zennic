import SwiftUI
import Core

public struct SettingsView: View {
    @StateObject private var appState = Core.appState
    @Environment(\.dismiss) private var dismiss
    
    public init() {}
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Form {
                Section {
                    Toggle("Use Dark Appearance", isOn: $appState.isDarkMode)
                } header: {
                    Text("Appearance")
                        .font(.headline)
                        .foregroundColor(.primary)
                }
            }
            .formStyle(.grouped)
            
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
