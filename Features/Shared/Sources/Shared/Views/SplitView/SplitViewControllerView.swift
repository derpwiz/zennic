import SwiftUI

/// A SwiftUI wrapper for NSSplitViewController that manages split view items
struct SplitViewControllerView: NSViewControllerRepresentable {
    /// The axis along which to split the views
    let axis: Axis
    
    /// The children views to display in the split view
    let children: _VariadicView.Children
    
    /// Binding to the view controller reference
    @Binding var viewController: () -> SplitViewController?
    
    func makeNSViewController(context: Context) -> SplitViewController {
        context.coordinator
    }
    
    func updateNSViewController(_ controller: SplitViewController, context: Context) {
        // Update items and their positions
        let hasChanged = controller.updateItems()
        
        // If items have changed and there are multiple items,
        // the divider positions will be updated automatically
        if hasChanged {
            // The coordinator reference is already up to date since
            // it's the same instance as the controller parameter
            context.coordinator.updateItems()
        }
    }
    
    func makeCoordinator() -> SplitViewController {
        SplitViewController(parent: self, axis: axis)
    }
}

/// Extension to provide a more SwiftUI-like API for SplitViewControllerView
extension SplitViewControllerView {
    /// Creates a split view controller view with the given axis and children
    /// - Parameters:
    ///   - axis: The axis along which to split the views
    ///   - children: The children views to display
    ///   - viewController: Binding to the view controller reference
    init(
        axis: Axis,
        children: _VariadicView.Children,
        viewController: Binding<() -> SplitViewController?>
    ) {
        self.axis = axis
        self.children = children
        self._viewController = viewController
    }
}
