import SwiftUI

/// A SwiftUI wrapper for NSSplitViewController that manages split view items
struct SplitViewControllerView<Content: View>: NSViewControllerRepresentable {
    /// The axis along which to split the views
    let axis: Axis
    
    /// The content to display in the split view
    let content: Content
    
    /// Binding to the view controller reference
    @Binding var viewController: () -> SplitViewController<Content>?
    
    func makeNSViewController(context: Context) -> SplitViewController<Content> {
        context.coordinator
    }
    
    func updateNSViewController(_ controller: SplitViewController<Content>, context: Context) {
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
    
    func makeCoordinator() -> SplitViewController<Content> {
        SplitViewController(parent: self, content: content, axis: axis)
    }
}
