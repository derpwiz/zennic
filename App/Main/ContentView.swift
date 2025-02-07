import SwiftUI
import Core
import UI

struct ContentView: View {
    @EnvironmentObject private var appState: AppState
    
    var body: some View {
        MainView()
            .environmentObject(appState)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(Core.appState)
    }
}
