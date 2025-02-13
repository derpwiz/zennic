import SwiftUI
import Documents
import DocumentsInterface

struct RealTimeMonitoringView<Document: WorkspaceDocumentProtocol>: View {
    @ObservedObject var workspace: Document
    
    init(workspace: Document) {
        self.workspace = workspace
    }
    
    var body: some View {
        FileTreeView(workspace: workspace)
    }
}

#if DEBUG
struct RealTimeMonitoringView_Previews: PreviewProvider {
    static var previews: some View {
        RealTimeMonitoringView(workspace: WorkspaceDocument())
    }
}
#endif
