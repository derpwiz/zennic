import SwiftUI

struct BacktestingView: View {
    var body: some View {
        VStack {
            Text("Backtesting")
                .font(.largeTitle)
            Text("This is where the backtesting features will be implemented.")
                .font(.subheadline)
        }
    }
}

struct BacktestingView_Previews: PreviewProvider {
    static var previews: some View {
        BacktestingView()
    }
}
