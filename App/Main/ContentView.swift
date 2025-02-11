import SwiftUI
import Core
import UI
import Documents

struct ContentView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var workspace: WorkspaceDocument
    
    var body: some View {
        MainView()
            .environmentObject(appState)
            .environmentObject(workspace)
    }
}

#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let workspace = WorkspaceDocument()
        workspace.selectedFeature = "CodeEditor"
        
        return ContentView()
            .environmentObject(AppState.shared)
            .environmentObject(workspace)
    }
}
#endif
