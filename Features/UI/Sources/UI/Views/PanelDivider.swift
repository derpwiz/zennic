import SwiftUI

/// A view that provides a visual divider between panels.
public struct PanelDivider: View {
    @Environment(\.colorScheme) private var colorScheme
    
    public init() {}
    
    public var body: some View {
        Divider()
            .background(colorScheme == .dark ? Color.black : Color.gray.opacity(0.2))
            .frame(height: 1)
    }
}

struct PanelDivider_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            Text("Above")
            PanelDivider()
            Text("Below")
        }
        .frame(width: 200, height: 100)
    }
}
