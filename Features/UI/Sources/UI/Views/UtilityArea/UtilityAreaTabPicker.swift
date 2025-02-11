import SwiftUI

/// A view that displays a segmented picker for utility area tabs
public struct UtilityAreaTabPicker: View {
    /// The currently selected tab
    @Binding var selection: UtilityAreaTab
    
    public init(selection: Binding<UtilityAreaTab>) {
        self._selection = selection
    }
    
    public var body: some View {
        Picker("Utility Area", selection: $selection) {
            ForEach(UtilityAreaTab.allCases, id: \.self) { tab in
                Text(tab.title)
                    .tag(tab)
            }
        }
        .pickerStyle(.segmented)
        .frame(width: 300)
    }
}

#if DEBUG
struct UtilityAreaTabPicker_Previews: PreviewProvider {
    static var previews: some View {
        UtilityAreaTabPicker(selection: .constant(.output))
            .padding()
    }
}
#endif
