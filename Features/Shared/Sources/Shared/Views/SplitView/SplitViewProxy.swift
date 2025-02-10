import SwiftUI

public struct SplitViewProxy {
    private let viewController: () -> SplitViewController?
    
    public init(viewController: @escaping () -> SplitViewController?) {
        self.viewController = viewController
    }
    
    public func setPosition(of index: Int, position: CGFloat) {
        viewController()?.setPosition(of: index, position: position)
    }
}
