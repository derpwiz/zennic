import SwiftUI
import Core
import UI
import Documents

struct ContentView: View {
    @EnvironmentObject private var appState: AppState
    @ObservedObject private var workspace: WorkspaceDocument
    
    init(workspace: WorkspaceDocument) {
        self.workspace = workspace
    }
    
    var body: some View {
        WorkspaceView(workspace: workspace)
            .environmentObject(appState)
            .environmentObject(EditorManager())
            .environmentObject(StatusBarViewModel())
            .environmentObject(UtilityAreaViewModel())
            .environmentObject(TaskManager())
    }
}

#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let workspace = WorkspaceDocument()
        workspace.selectedFeature = "CodeEditor"
        
        return ContentView(workspace: workspace)
            .environmentObject(AppState.shared)
    }
}
#endif
