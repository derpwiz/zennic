import SwiftUI

/// Terminal view for the utility area
public struct UtilityAreaTerminalView: View {
    @StateObject private var model = UtilityAreaTabViewModel()
    
    public var body: some View {
        UtilityAreaTabView(model: model) { _ in
            VStack {
                Text("Terminal")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .paneToolbar {
                PaneToolbarSection {
                    Button {
                        // Reset terminal
                    } label: {
                        Image(systemName: "trash")
                    }
                    .help("Reset the terminal")
                    .buttonStyle(.icon())
                    
                    Button {
                        // Split terminal
                    } label: {
                        Image(systemName: "square.split.2x1")
                    }
                    .help("Split terminal")
                    .buttonStyle(.icon())
                }
            }
        }
    }
}

extension View {
    func paneToolbar<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        self.overlay(alignment: .bottom) {
            PaneToolbar {
                content()
            }
        }
    }
}
