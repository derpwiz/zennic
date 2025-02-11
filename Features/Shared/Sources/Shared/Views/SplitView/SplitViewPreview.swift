import SwiftUI

struct SplitViewPreview: PreviewProvider {
    static var previews: some View {
        SplitView {
            Color.red
                .frame(minWidth: 200, maxWidth: 300)
                .canCollapse()
                .id("left-pane")
            
            Color.blue
                .frame(maxWidth: .infinity)
            
            SplitViewReader { controller in
                Color.green
                    .frame(width: 200)
                    .overlay(alignment: .topLeading) {
                        Button("Toggle Left") {
                            controller.collapse(for: "left-pane", enabled: true)
                        }
                        .padding()
                    }
            }
        }
        .frame(width: 800, height: 400)
    }
}
