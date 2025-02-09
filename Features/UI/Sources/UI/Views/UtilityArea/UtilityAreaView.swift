import SwiftUI

/// The main view for the utility area.
/// A view that displays the utility area with tabs and resizable content
public struct UtilityAreaView: View {
    /// The current color scheme
    @Environment(\.colorScheme) private var colorScheme
    
    /// The utility area view model
    @EnvironmentObject private var viewModel: UtilityAreaViewModel
    
    /// Creates a new utility area view
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
                        viewModel.togglePanel()
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
                        OutputView(text: $viewModel.outputViewModel.text)
                    case .debug:
                        DebugView()
                    case .terminal:
                        TerminalView(workingDirectory: FileManager.default.currentDirectoryPath)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(height: viewModel.isCollapsed ? 29 : viewModel.height)
        .background(EffectView(.contentBackground))
    }
}

/// A view that wraps the utility area in a split view
public struct UtilityAreaSplitView<Content: View>: View {
    /// The content to display above the utility area
    private let content: Content
    
    /// The utility area view model
    @StateObject private var viewModel = UtilityAreaViewModel()
    
    /// Creates a new utility area split view
    /// - Parameter content: The content to display above the utility area
    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    public var body: some View {
        SplitView.vertical {
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            UtilityAreaView()
                .frame(height: viewModel.isCollapsed ? 29 : viewModel.height)
                .animation(.spring(), value: viewModel.isCollapsed)
                .animation(.spring(), value: viewModel.isMaximized)
        }
        .environmentObject(viewModel)
    }
}

struct UtilityAreaView_Previews: PreviewProvider {
    static var previews: some View {
        UtilityAreaView()
            .environmentObject(UtilityAreaViewModel())
            .frame(width: 800, height: 300)
    }
}
