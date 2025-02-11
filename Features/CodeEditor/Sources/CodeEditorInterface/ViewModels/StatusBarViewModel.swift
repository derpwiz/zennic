import SwiftUI

/// Represents the dimensions of an image
public struct ImageDimensions {
    let width: Int
    let height: Int
}

/// View model for the status bar
public final class StatusBarViewModel: ObservableObject {
    /// The status bar model containing all the state
    @Published public var model: StatusBarModel?

    /// The font style of items shown in the status bar
    public private(set) var statusBarFont = Font.system(size: 11, weight: .medium)

    /// The color of the text shown in the status bar
    public private(set) var foregroundStyle = Color.secondary
    
    public init() {}
}
