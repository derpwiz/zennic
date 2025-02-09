import SwiftUI

/// A SwiftUI wrapper for NSSplitViewController that manages split view items
struct SplitViewControllerView: NSViewControllerRepresentable {
    /// The axis along which to split the views
    let axis: Axis
    
    /// The content to display in the split view
    let content: AnyView
    
    /// Binding to the view controller reference
    @Binding var viewController: () -> SplitViewController<AnyView>?
    
    func makeNSViewController(context: Context) -> SplitViewController<AnyView> {
        context.coordinator
    }
    
    func updateNSViewController(_ controller: SplitViewController<AnyView>, context: Context) {
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
    
    func makeCoordinator() -> SplitViewController<AnyView> {
        SplitViewController(parent: self, content: content, axis: axis)
    }
}
