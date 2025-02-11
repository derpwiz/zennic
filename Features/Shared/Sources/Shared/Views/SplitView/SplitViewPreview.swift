import SwiftUI

struct SplitViewPreview: PreviewProvider {
    static var previews: some View {
        SplitView.horizontal {
            Color.red
                .frame(minWidth: 200, maxWidth: 300)
                .collapsible()
            
            Color.blue
                .frame(maxWidth: .infinity)
            
            SplitViewReader { controller in
                Color.green
                    .frame(width: 200)
                    .overlay(alignment: .topLeading) {
                        Button("Toggle Left") {
                            controller.collapseView(with: "split-view-item-true", true)
                        }
                        .padding()
                    }
            }
        }
        .frame(width: 800, height: 400)
    }
}
