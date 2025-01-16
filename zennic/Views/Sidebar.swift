import SwiftUI

/// Navigation sidebar view providing access to main app sections
/// Displays a list of navigation items with icons and labels
struct Sidebar: View {
    @Binding var selection: NavigationItem    // Currently selected navigation item
    
    var body: some View {
        List(selection: $selection) {
            // Create navigation links for each main section of the app
            ForEach([
                NavigationItem.dashboard,
                NavigationItem.portfolio,
                NavigationItem.trading,
                NavigationItem.analysis,
                NavigationItem.settings
            ], id: \.self) { item in
                NavigationLink(value: item) {
                    Label(item.title, systemImage: item.icon)
                }
            }
        }
        .navigationTitle("AI Hedge Fund")
        .listStyle(.sidebar)
    }
}

/// Preview provider for SwiftUI canvas
struct Sidebar_Previews: PreviewProvider {
    static var previews: some View {
        Sidebar(selection: .constant(.dashboard))
    }
}
