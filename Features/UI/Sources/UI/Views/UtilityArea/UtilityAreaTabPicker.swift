import SwiftUI

/// A view that displays a segmented picker for utility area tabs
struct UtilityAreaTabPicker: View {
    /// The currently selected tab
    @Binding var selection: UtilityAreaTab
    
    var body: some View {
        Picker("Utility Area", selection: $selection) {
            ForEach(UtilityAreaTab.allCases, id: \.self) { tab in
                Text(tab.name)
                    .tag(tab)
            }
        }
        .pickerStyle(.segmented)
        .frame(width: 300)
    }
}

struct UtilityAreaTabPicker_Previews: PreviewProvider {
    static var previews: some View {
        UtilityAreaTabPicker(selection: .constant(.output))
            .padding()
    }
}
