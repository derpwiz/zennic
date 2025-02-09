import SwiftUI

/// A view that wraps NSVisualEffectView to provide system material effects.
public struct EffectView: NSViewRepresentable {
    private let material: NSVisualEffectView.Material
    private let blendingMode: NSVisualEffectView.BlendingMode
    private let emphasized: Bool
    
    /// Creates an effect view with the specified material.
    /// - Parameters:
    ///   - material: The material to use for the effect.
    ///   - blendingMode: The blending mode to use.
    ///   - emphasized: Whether the effect should be emphasized.
    public init(
        _ material: NSVisualEffectView.Material = .contentBackground,
        blendingMode: NSVisualEffectView.BlendingMode = .behindWindow,
        emphasized: Bool = false
    ) {
        self.material = material
        self.blendingMode = blendingMode
        self.emphasized = emphasized
    }
    
    public func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.isEmphasized = emphasized
        view.state = .active
        return view
    }
    
    public func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
        nsView.isEmphasized = emphasized
    }
}
