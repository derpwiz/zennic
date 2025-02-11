//
//  DocumentUtilityAreaView.swift
//  Documents
//
//  Created by Claude on 2/11/25.
//

import SwiftUI
import UtilityArea

/// A simplified utility area view that uses UtilityArea module components
struct DocumentUtilityAreaView: View {
    @EnvironmentObject private var viewModel: UtilityAreaViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            // Simple utility area implementation
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

#if DEBUG
struct DocumentUtilityAreaView_Previews: PreviewProvider {
    static var previews: some View {
        DocumentUtilityAreaView()
            .environmentObject(UtilityAreaViewModel())
    }
}
#endif
