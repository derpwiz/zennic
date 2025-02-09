import SwiftUI

/// The main view for the utility area.
public struct UtilityAreaView: View {
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var viewModel: UtilityAreaViewModel
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack(spacing: 0) {
                // Tab picker
                Picker("", selection: $viewModel.selectedTab) {
                    ForEach(UtilityAreaTab.allCases, id: \.self) { tab in
                        Label {
                            Text(tab.name)
                        } icon: {
                            Image(systemName: tab.icon)
                        }
                        .tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 300)
                
                Spacer()
                
                // Toolbar buttons
                HStack(spacing: 2) {
                    UtilityAreaToolbarButton(
                        systemImage: viewModel.isCollapsed ? "chevron.up" : "chevron.down",
                        isActive: !viewModel.isCollapsed
                    ) {
                        viewModel.toggleCollapsed()
                    }
                    
                    UtilityAreaToolbarButton(
                        systemImage: viewModel.isMaximized ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right",
                        isActive: viewModel.isMaximized
                    ) {
                        viewModel.toggleMaximized()
                    }
                }
                .padding(.horizontal, 8)
            }
            .frame(height: 29)
            .background(EffectView(.contentBackground))
            
            if !viewModel.isCollapsed {
                // Content
                Group {
                    switch viewModel.selectedTab {
                    case .output:
                        EmptyView() // TODO: Implement output view
                    case .debug:
                        EmptyView() // TODO: Implement debug view
                    case .terminal:
                        EmptyView() // TODO: Implement terminal view
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(EffectView(.contentBackground))
    }
}

struct UtilityAreaView_Previews: PreviewProvider {
    static var previews: some View {
        UtilityAreaView()
            .environmentObject(UtilityAreaViewModel())
            .frame(width: 800, height: 300)
    }
}
