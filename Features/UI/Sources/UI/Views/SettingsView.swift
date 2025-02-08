import SwiftUI
import Core
import Shared

public struct SettingsView: View {
    @EnvironmentObject private var appState: AppState
    @ObservedObject private var themeModel: ThemeModel = .shared
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var isShowingWorkspacePicker = false
    
    public init() {}
    
    private var currentTheme: Theme {
        themeModel.selectedTheme ?? (colorScheme == .dark ? .darkDefault : .lightDefault)
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Form {
                Section {
                    Toggle("Use Dark Appearance", isOn: $appState.isDarkMode)
                        .onChange(of: appState.isDarkMode) { newValue in
                            themeModel.updateTheme(for: newValue ? .dark : .light)
                        }
                    
                    Picker("Theme", selection: Binding(
                        get: { themeModel.selectedTheme?.name ?? (colorScheme == .dark ? "Dark" : "Light") },
                        set: { newValue in
                            if let theme = themeModel.themes.first(where: { $0.name == newValue }) {
                                themeModel.selectedTheme = theme
                            }
                        }
                    )) {
                        ForEach(themeModel.themes.filter { $0.appearance == (appState.isDarkMode ? .dark : .light) }, id: \.name) { theme in
                            Text(theme.name).tag(theme.name)
                        }
                    }
                } header: {
                    Text("Appearance")
                        .font(.headline)
                        .foregroundColor(currentTheme.editor.text)
                }
                
                Section {
                    HStack {
                        Text("Path")
                            .foregroundColor(currentTheme.editor.text)
                        Spacer()
                        Button(appState[keyPath: \.workspacePath].isEmpty ? "Select" : appState[keyPath: \.workspacePath]) {
                            isShowingWorkspacePicker = true
                        }
                    }
                } header: {
                    Text("Workspace")
                        .font(.headline)
                        .foregroundColor(currentTheme.editor.text)
                }
            }
            .formStyle(.grouped)
            .background(EffectView(.contentBackground))
            
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .fileImporter(
            isPresented: $isShowingWorkspacePicker,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    appState[keyPath: \.workspacePath] = url.path
                }
            case .failure(let error):
                print("Error selecting workspace: \(error.localizedDescription)")
            }
        }
        .onAppear {
            themeModel.updateTheme(for: colorScheme)
        }
        .onChange(of: colorScheme) { newValue in
            themeModel.updateTheme(for: newValue)
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(AppState.shared)
    }
}
