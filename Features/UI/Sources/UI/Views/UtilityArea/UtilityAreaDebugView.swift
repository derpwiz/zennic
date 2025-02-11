import SwiftUI

/// Debug console view for the utility area
public struct UtilityAreaDebugView: View {
    @StateObject private var model = UtilityAreaTabViewModel(hasLeadingSidebar: true)
    
    public var body: some View {
        UtilityAreaTabView(model: model) { _ in
            VStack {
                Text("No Task Selected")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .paneToolbar {
                PaneToolbarSection {
                    Button {
                        // Clear console
                    } label: {
                        Image(systemName: "trash")
                    }
                    .help("Clear console")
                    .buttonStyle(.icon())
                    
                    Button {
                        // Filter console
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                    .help("Filter console")
                    .buttonStyle(.icon())
                }
            }
        } leadingSidebar: { _ in
            VStack {
                Text("No Tasks are Running")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .paneToolbar {
                Spacer()
            }
        }
    }
}
