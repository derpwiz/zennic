//
//  NavigationSplitView.swift
//  Documents
//
//  Created by Claude on 2/11/25.
//

import SwiftUI

/// A split view that shows navigation on the left and content on the right.
public struct NavigationSplitView<Content: View, Detail: View>: View {
    private let content: () -> Content
    private let detail: () -> Detail

    public init(
        @ViewBuilder content: @escaping () -> Content,
        @ViewBuilder detail: @escaping () -> Detail
    ) {
        self.content = content
        self.detail = detail
    }

    public var body: some View {
        HSplitView {
            content()
                .frame(minWidth: 200, maxWidth: .infinity)
            detail()
                .frame(maxWidth: .infinity)
        }
    }
}
