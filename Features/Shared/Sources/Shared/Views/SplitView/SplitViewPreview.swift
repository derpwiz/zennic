import SwiftUI

struct SplitViewPreview: PreviewProvider {
    static var previews: some View {
        SplitView<TupleView<(
            ModifiedContent<Color, _FrameLayout>,
            ModifiedContent<Color, _FrameLayout>,
            ModifiedContent<SplitViewReader<ModifiedContent<Color, _OverlayModifier<ModifiedContent<Button<Text>, _PaddingLayout>>>>, _FrameLayout>
        )>>.horizontal {
            Color.red
                .frame(minWidth: 200, maxWidth: 300)
                .canCollapse()
            
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
