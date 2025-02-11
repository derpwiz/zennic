import SwiftUI

/// Output view for the utility area
public struct UtilityAreaOutputView: View {
    @StateObject private var model = UtilityAreaTabViewModel()
    @State private var filterText = ""
    @State private var selectedSource: String?
    
    var body: some View {
        UtilityAreaTabView(model: model) { _ in
            VStack {
                Text("No output")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .paneToolbar {
                PaneToolbarSection {
                    Picker("Output Source", selection: $selectedSource) {
                        Text("All Sources")
                            .tag(nil as String?)
                        Text("Source 1")
                            .tag("source1" as String?)
                        Text("Source 2")
                            .tag("source2" as String?)
                    }
                    .buttonStyle(.borderless)
                    .labelsHidden()
                    .controlSize(.small)
                }
                
                Spacer()
                
                PaneToolbarSection {
                    TextField("Filter", text: $filterText)
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: 175)
                    
                    Button {
                        // Clear output
                    } label: {
                        Image(systemName: "trash")
                    }
                    .help("Clear output")
                    .buttonStyle(.icon())
                }
            }
        }
    }
}
