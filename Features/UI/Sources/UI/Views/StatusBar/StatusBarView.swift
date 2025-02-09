import SwiftUI

/// The main view for the status bar.
public struct StatusBarView: View {
    @StateObject private var viewModel = StatusBarViewModel()
    @EnvironmentObject private var utilityAreaViewModel: UtilityAreaViewModel
    
    public init() {}
    
    public var body: some View {
        HStack(spacing: StatusBarIconDimensions.spacing) {
            // Left items
            HStack(spacing: StatusBarIconDimensions.spacing) {
                StatusBarFileInfoView()
                StatusBarCursorPositionLabel()
            }
            
            Spacer()
            
            // Right items
            HStack(spacing: StatusBarIconDimensions.spacing) {
                StatusBarLineEndSelector()
                StatusBarIndentSelector()
                StatusBarEncodingSelector()
                
                Divider()
                    .frame(height: 12)
                
                StatusBarToggleUtilityAreaButton()
            }
        }
        .padding(.horizontal, 8)
        .frame(height: 29)
        .background(EffectView(.contentBackground))
        .environmentObject(viewModel)
    }
}

struct StatusBarView_Previews: PreviewProvider {
    static var previews: some View {
        StatusBarView()
            .environmentObject(UtilityAreaViewModel())
            .frame(width: 800)
    }
}
