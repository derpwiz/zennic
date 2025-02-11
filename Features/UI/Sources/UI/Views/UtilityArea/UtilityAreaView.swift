import SwiftUI

/// The main utility area view that manages tabs and visibility
public struct UtilityAreaView: View {
    @EnvironmentObject private var viewModel: UtilityAreaViewModel
    @State private var hoveredTab: UtilityAreaTab?
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 0) {
            // Tab bar
            HStack(spacing: 0) {
                // Tab picker
                WorkspacePanelTabBar(
                    items: Array(UtilityAreaTab.allCases),
                    selection: $viewModel.selectedTab,
                    position: .top
                )
                .padding(.horizontal, 10)
                
                Spacer()
                
                // Toolbar buttons
                HStack(spacing: 4) {
                    Button {
                        viewModel.toggleMaximized()
                    } label: {
                        Image(systemName: viewModel.isMaximized ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
                    }
                    .buttonStyle(.icon())
                    .help(viewModel.isMaximized ? "Exit Full Screen" : "Enter Full Screen")
                    
                    Button {
                        viewModel.toggleCollapsed()
                    } label: {
                        Image(systemName: "chevron.down")
                            .rotationEffect(viewModel.isCollapsed ? .zero : .degrees(180))
                    }
                    .buttonStyle(.icon())
                    .help(viewModel.isCollapsed ? "Show Utility Area" : "Hide Utility Area")
                }
                .padding(.trailing, 10)
            }
            .frame(height: 28)
            .background(.bar)
            
            // Tab content
            if let selectedTab = viewModel.selectedTab {
                selectedTab
                    .environmentObject(viewModel)
            } else {
                Text("No Tab Selected")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(.background)
    }
}

/// A button that toggles the utility area collapsed state
public struct UtilityAreaToggleButton: View {
    @ObservedObject var viewModel: UtilityAreaViewModel
    
    public init(viewModel: UtilityAreaViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        Button {
            viewModel.toggleCollapsed()
        } label: {
            Image(systemName: "rectangle.bottomthird.inset.filled")
                .symbolVariant(viewModel.isCollapsed ? .none : .fill)
        }
        .help("Toggle Utility Area")
        .buttonStyle(.icon(isActive: !viewModel.isCollapsed))
    }
}
