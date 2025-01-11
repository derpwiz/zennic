import SwiftUI

struct Sidebar: View {
    @Binding var selection: NavigationItem
    
    var body: some View {
        List(selection: $selection) {
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

struct Sidebar_Previews: PreviewProvider {
    static var previews: some View {
        Sidebar(selection: .constant(.dashboard))
    }
}
