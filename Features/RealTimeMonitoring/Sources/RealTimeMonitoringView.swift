import SwiftUI
import Documents

struct RealTimeMonitoringView: View {
    @EnvironmentObject private var workspace: WorkspaceDocument
    
    var body: some View {
        FileTreeView()
            .environmentObject(workspace)
    }
}

#if DEBUG
struct RealTimeMonitoringView_Previews: PreviewProvider {
    static var previews: some View {
        let workspace = WorkspaceDocument()
        return RealTimeMonitoringView()
            .environmentObject(workspace)
    }
}
#endif
