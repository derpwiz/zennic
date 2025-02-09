import SwiftUI

/// A button used in the utility area toolbar.
struct UtilityAreaToolbarButton: View {
    let systemImage: String
    let action: () -> Void
    let isActive: Bool
    
    init(
        systemImage: String,
        isActive: Bool = false,
        action: @escaping () -> Void
    ) {
        self.systemImage = systemImage
        self.isActive = isActive
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(isActive ? .primary : .secondary)
                .frame(width: 24, height: 24)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

struct UtilityAreaToolbarButton_Previews: PreviewProvider {
    static var previews: some View {
        HStack {
            UtilityAreaToolbarButton(systemImage: "chevron.down") {}
            UtilityAreaToolbarButton(systemImage: "arrow.up.left.and.arrow.down.right") {}
            UtilityAreaToolbarButton(systemImage: "xmark", isActive: true) {}
        }
        .padding()
    }
}
