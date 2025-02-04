import SwiftUI
import Core

public struct SettingsView: View {
    @StateObject private var appState = Core.appState
    @Environment(\.dismiss) private var dismiss
    
    public init() {}
    
    public var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .simultaneousGesture(TapGesture().onEnded {
                    dismiss()
                })
            
            Form {
                Section {
                    Toggle("Dark Mode", isOn: $appState.isDarkMode)
                } header: {
                    Text("General")
                        .font(.headline)
                }
            }
            .formStyle(.grouped)
            .padding()
            .frame(width: 375, height: 200)
            .background(Color(.windowBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
