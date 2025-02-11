//
//  CodeEditSplitViewController.swift
//  Documents
//
//  Created by Claude on 2/11/25.
//

import Cocoa
import SwiftUI
import Editor
import UtilityArea
import Core

public final class CodeEditSplitViewController: NSSplitViewController {
    public static let minSidebarWidth: CGFloat = 242
    public static let maxSnapWidth: CGFloat = snapWidth + 10
    public static let snapWidth: CGFloat = 272
    public static let minSnapWidth: CGFloat = snapWidth - 10

    private weak var workspace: WorkspaceDocument?
    private weak var windowRef: NSWindow?
    private unowned var hapticPerformer: NSHapticFeedbackPerformer

    // MARK: - Initialization

    public init(
        workspace: WorkspaceDocument,
        windowRef: NSWindow,
        hapticPerformer: NSHapticFeedbackPerformer = NSHapticFeedbackManager.defaultPerformer
    ) {
        self.workspace = workspace
        self.windowRef = windowRef
        self.hapticPerformer = hapticPerformer
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        guard let windowRef else {
            assertionFailure("No WindowRef found, not initialized properly or the window was dereferenced and the controller was not.")
            return
        }

        guard let workspace,
              let editorManager = workspace.editorManager,
              let statusBarViewModel = workspace.statusBarViewModel,
              let utilityAreaModel = workspace.utilityAreaModel else {
            assertionFailure("Missing a workspace model")
            return
        }

        splitView.translatesAutoresizingMaskIntoConstraints = false

        let navigator = makeNavigator(view: SettingsInjector {
            NavigationSplitView {
                SidebarNavigationView(selectedFeature: Binding(
                    get: { workspace.selectedFeature },
                    set: { workspace.selectedFeature = $0 }
                ))
            } detail: {
                EmptyView()
            }
            .environmentObject(workspace)
            .environmentObject(editorManager)
        })

        addSplitViewItem(navigator)

        let workspaceView = SettingsInjector {
            WindowObserver(window: WindowBox(value: windowRef)) {
                DocumentContentView()
                    .environmentObject(workspace)
                    .environmentObject(editorManager)
                    .environmentObject(statusBarViewModel)
                    .environmentObject(utilityAreaModel)
            }
        }

        let mainContent = NSSplitViewItem(viewController: NSHostingController(rootView: workspaceView))
        mainContent.titlebarSeparatorStyle = .line
        mainContent.minimumThickness = 200

        addSplitViewItem(mainContent)
    }

    private func makeNavigator(view: some View) -> NSSplitViewItem {
        let navigator = NSSplitViewItem(sidebarWithViewController: NSHostingController(rootView: view))
        navigator.titlebarSeparatorStyle = .none
        navigator.isSpringLoaded = true
        navigator.minimumThickness = Self.minSidebarWidth
        navigator.collapseBehavior = .useConstraints
        return navigator
    }

    public override func viewWillAppear() {
        super.viewWillAppear()

        guard let workspace else { return }

        let navigatorWidth = workspace.getFromWorkspaceState(.splitViewWidth) as? CGFloat
        splitView.setPosition(navigatorWidth ?? Self.minSidebarWidth, ofDividerAt: 0)

        if let firstSplitView = splitViewItems.first {
            firstSplitView.isCollapsed = workspace.getFromWorkspaceState(
                .navigatorCollapsed
            ) as? Bool ?? false
        }
    }

    // MARK: - NSSplitViewDelegate

    public override func splitView(
        _ splitView: NSSplitView,
        constrainSplitPosition proposedPosition: CGFloat,
        ofSubviewAt dividerIndex: Int
    ) -> CGFloat {
        switch dividerIndex {
        case 0:
            // Navigator
            if (Self.minSnapWidth...Self.maxSnapWidth).contains(proposedPosition) {
                return Self.snapWidth
            } else if proposedPosition <= Self.minSidebarWidth / 2 {
                hapticCollapse(splitViewItems.first, collapseAction: true)
                return 0
            } else {
                hapticCollapse(splitViewItems.first, collapseAction: false)
                return max(Self.minSidebarWidth, proposedPosition)
            }
        default:
            return proposedPosition
        }
    }

    private func hapticCollapse(_ item: NSSplitViewItem?, collapseAction: Bool) {
        if item?.isCollapsed == !collapseAction {
            hapticPerformer.perform(.alignment, performanceTime: .now)
        }
        item?.isCollapsed = collapseAction
    }

    public override func splitViewDidResizeSubviews(_ notification: Notification) {
        super.splitViewDidResizeSubviews(notification)
        guard let resizedDivider = notification.userInfo?["NSSplitViewDividerIndex"] as? Int else {
            return
        }

        if resizedDivider == 0 {
            let panel = splitView.subviews[0]
            let width = panel.frame.size.width
            if width > 0 {
                workspace?.addToWorkspaceState(key: .splitViewWidth, value: width)
            }
        }
    }

    public func saveNavigatorCollapsedState(isCollapsed: Bool) {
        workspace?.addToWorkspaceState(key: .navigatorCollapsed, value: isCollapsed)
    }
}

// MARK: - Helper Views

public struct WindowBox {
    public let value: NSWindow?

    public init(value: NSWindow?) {
        self.value = value
    }
}

public struct WindowObserver<Content: View>: View {
    public let window: WindowBox
    public let content: () -> Content

    public init(window: WindowBox, @ViewBuilder content: @escaping () -> Content) {
        self.window = window
        self.content = content
    }

    public var body: some View {
        content()
    }
}

public struct SettingsInjector<Content: View>: View {
    public let content: () -> Content

    public init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    public var body: some View {
        content()
    }
}
