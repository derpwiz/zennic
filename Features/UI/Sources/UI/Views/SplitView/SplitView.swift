import SwiftUI

/// A view that arranges its children in a horizontal or vertical stack with resizable dividers.
public struct SplitView: View {
    private let axis: Axis
    private let content: [AnyView]
    private let spacing: CGFloat
    
    @State private var fractions: [CGFloat]
    @State private var oldFractions: [CGFloat]
    @State private var dragging: Int?
    
    /// Creates a split view with the given axis and content.
    /// - Parameters:
    ///   - axis: The axis to stack the content on.
    ///   - spacing: The spacing between views.
    ///   - content: A ViewBuilder closure that creates the content of this stack.
    public init(
        axis: Axis = .horizontal,
        spacing: CGFloat = 1,
        @ViewBuilder content: () -> some View
    ) {
        self.axis = axis
        self.spacing = spacing
        
        // Get an array of children from the ViewBuilder
        let views = content()
        if let viewTuple = views.getViews() {
            self.content = viewTuple
        } else {
            self.content = [AnyView(views)]
        }
        
        // Initialize the fractions equally
        let fraction = 1.0 / CGFloat(self.content.count)
        self._fractions = State(initialValue: Array(repeating: fraction, count: self.content.count))
        self._oldFractions = State(initialValue: Array(repeating: fraction, count: self.content.count))
    }
    
    public var body: some View {
        GeometryReader { geometry in
            let totalSpacing = spacing * CGFloat(content.count - 1)
            let size = axis == .horizontal ? geometry.size.width : geometry.size.height
            let totalSize = size - totalSpacing
            
            ZStack(alignment: .topLeading) {
                // Content views
                ForEach(0..<content.count, id: \.self) { index in
                    content[index]
                        .frame(
                            width: axis == .horizontal ? fractions[index] * totalSize : nil,
                            height: axis == .vertical ? fractions[index] * totalSize : nil
                        )
                        .offset(
                            x: axis == .horizontal ? calculateOffset(at: index, totalSize: totalSize) : 0,
                            y: axis == .vertical ? calculateOffset(at: index, totalSize: totalSize) : 0
                        )
                }
                
                // Dividers
                ForEach(0..<content.count-1, id: \.self) { index in
                    SplitDivider(axis: axis)
                        .position(
                            x: axis == .horizontal ? calculateDividerPosition(at: index, totalSize: totalSize) : geometry.size.width/2,
                            y: axis == .vertical ? calculateDividerPosition(at: index, totalSize: totalSize) : geometry.size.height/2
                        )
                        .gesture(
                            DragGesture()
                                .onChanged { gesture in
                                    if dragging == nil {
                                        dragging = index
                                        oldFractions = fractions
                                    }
                                    
                                    guard let dragging = dragging else { return }
                                    
                                    // Convert gesture translation to fraction
                                    let translation = axis == .horizontal ? gesture.translation.width : gesture.translation.height
                                    let translationAsFraction = translation / totalSize
                                    
                                    // Update fractions
                                    var newFractions = oldFractions
                                    newFractions[dragging] += translationAsFraction
                                    newFractions[dragging + 1] -= translationAsFraction
                                    
                                    // Ensure fractions stay within bounds
                                    if newFractions[dragging] >= 0.1 && newFractions[dragging + 1] >= 0.1 {
                                        fractions = newFractions
                                    }
                                }
                                .onEnded { _ in
                                    dragging = nil
                                }
                        )
                }
            }
        }
    }
    
    private func calculateOffset(at index: Int, totalSize: CGFloat) -> CGFloat {
        guard index > 0 else { return 0 }
        let offset = fractions[..<index].reduce(0, +) * totalSize + spacing * CGFloat(index)
        return offset
    }
    
    private func calculateDividerPosition(at index: Int, totalSize: CGFloat) -> CGFloat {
        let position = fractions[...index].reduce(0, +) * totalSize + spacing * CGFloat(index)
        return position
    }
}

private struct SplitDivider: View {
    let axis: Axis
    
    var body: some View {
        Rectangle()
            .fill(Color.gray.opacity(0.2))
            .frame(
                width: axis == .horizontal ? 1 : 40,
                height: axis == .vertical ? 1 : 40
            )
            .contentShape(Rectangle())
    }
}

private extension View {
    func getViews() -> [AnyView]? {
        if let tupleView = Mirror(reflecting: self).children.first?.value {
            let tupleMirror = Mirror(reflecting: tupleView)
            return tupleMirror.children.map { AnyView(_fromValue: $0.value)! }
        }
        return nil
    }
}
