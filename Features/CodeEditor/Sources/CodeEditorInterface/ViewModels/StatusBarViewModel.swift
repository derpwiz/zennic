import SwiftUI

/// Represents the dimensions of an image
public struct ImageDimensions {
    let width: Int
    let height: Int
}

/// View model for the status bar
public final class StatusBarViewModel: ObservableObject {
    /// The file size of the currently opened file
    @Published public var fileSize: Int?

    /// The dimensions (width x height) of the currently opened image
    @Published public var dimensions: ImageDimensions?

    /// Indicates whether the breakpoint is enabled or not
    @Published public var isBreakpointEnabled = true

    /// The font style of items shown in the status bar
    public private(set) var statusBarFont = Font.system(size: 11, weight: .medium)

    /// The color of the text shown in the status bar
    public private(set) var foregroundStyle = Color.secondary
    
    public init() {}
}
