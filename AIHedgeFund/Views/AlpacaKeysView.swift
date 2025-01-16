import SwiftUI

struct AlpacaKeysView: View {
    @EnvironmentObject private var appViewModel: AppViewModel
    
    var body: some View {
        VStack {
            Text("Alpaca Keys")
                .font(.title)
            Text("Coming soon...")
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    AlpacaKeysView()
}
