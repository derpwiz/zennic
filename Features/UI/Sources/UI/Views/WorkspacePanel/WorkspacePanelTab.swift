import SwiftUI

/// Protocol defining the requirements for a workspace panel tab
public protocol WorkspacePanelTab: View, Identifiable, Hashable {
    var title: String { get }
    var systemImage: String { get }
}

/// The position of the tab bar in the workspace panel
public enum TabBarPosition {
    case top
    case side
}

/// A tab bar view for workspace panels that supports drag and drop reordering
public struct WorkspacePanelTabBar<Tab: WorkspacePanelTab>: View {
    @Binding public var items: [Tab]
    @Binding public var selection: Tab?
    
    public var position: TabBarPosition
    
    @State private var tabLocations: [Tab: CGRect] = [:]
    @State private var tabWidth: [Tab: CGFloat] = [:]
    @State private var tabOffsets: [Tab: CGFloat] = [:]
    
    /// The tab currently being dragged
    @State private var draggingTab: Tab?
    
    /// The start location of dragging
    @State private var draggingStartLocation: CGFloat?
    
    /// The last location of dragging
    @State private var draggingLastLocation: CGFloat?
    
    public init(items: [Tab], selection: Binding<Tab?>, position: TabBarPosition) {
        self._items = Binding(projectedValue: .constant(items))
        self._selection = selection
        self.position = position
    }
    
    public var body: some View {
        if position == .top {
            topBody
        } else {
            sideBody
        }
    }
    
    var topBody: some View {
        GeometryReader { proxy in
            iconsView(size: proxy.size)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .animation(.default, value: items)
        }
        .clipped()
        .frame(maxWidth: .infinity, idealHeight: 27)
        .fixedSize(horizontal: false, vertical: true)
    }
    
    var sideBody: some View {
        GeometryReader { proxy in
            iconsView(size: proxy.size)
                .padding(.vertical, 5)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .animation(.default, value: items)
        }
        .clipped()
        .frame(idealWidth: 40, maxHeight: .infinity)
        .fixedSize(horizontal: true, vertical: false)
    }
    
    @ViewBuilder
    func iconsView(size: CGSize) -> some View {
        let layout = position == .top
            ? AnyLayout(HStackLayout(spacing: 0))
            : AnyLayout(VStackLayout(spacing: 0))
        layout {
            ForEach(items) { tab in
                makeIcon(tab: tab, size: size)
                    .offset(
                        x: (position == .top) ? (tabOffsets[tab] ?? 0) : 0,
                        y: (position == .side) ? (tabOffsets[tab] ?? 0) : 0
                    )
                    .background(makeTabItemGeometryReader(tab: tab))
                    .simultaneousGesture(makeAreaTabDragGesture(tab: tab))
            }
            if position == .side {
                Spacer()
            }
        }
    }
    
    private func makeIcon(
        tab: Tab,
        scale: Image.Scale = .medium,
        size: CGSize
    ) -> some View {
        Button {
            selection = tab
        } label: {
            Image(systemName: tab.systemImage)
                .font(.system(size: 12.5))
                .symbolVariant(tab == selection ? .fill : .none)
                .help(tab.title)
        }
        .buttonStyle(.borderless)
        .frame(
            width: position == .side ? 40 : 24,
            height: position == .side ? 28 : size.height
        )
        .contentShape(Rectangle())
        .focusable(false)
        .accessibilityIdentifier("WorkspacePanelTab-\(tab.title)")
        .accessibilityLabel(tab.title)
    }
    
    private func makeAreaTabDragGesture(tab: Tab) -> some Gesture {
        DragGesture(minimumDistance: 2, coordinateSpace: .global)
            .onChanged({ value in
                if draggingTab != tab {
                    initializeDragGesture(value: value, for: tab)
                }
                
                // Get the current cursor location
                let currentLocation = (position == .top) ? value.location.x : value.location.y
                guard let startLocation = draggingStartLocation,
                      let currentIndex = items.firstIndex(of: tab),
                      let currentTabWidth = tabWidth[tab],
                      let lastLocation = draggingLastLocation
                else { return }
                
                let dragDifference = currentLocation - lastLocation
                tabOffsets[tab] = currentLocation - startLocation
                
                // Check for swaps between adjacent tabs
                // Left/Top tab
                swapTab(
                    tab: tab,
                    currentIndex: currentIndex,
                    currentLocation: currentLocation,
                    dragDifference: dragDifference,
                    currentTabWidth: currentTabWidth,
                    direction: .previous
                )
                // Right/Bottom tab
                swapTab(
                    tab: tab,
                    currentIndex: currentIndex,
                    currentLocation: currentLocation,
                    dragDifference: dragDifference,
                    currentTabWidth: currentTabWidth,
                    direction: .next
                )
                
                // Update the last dragging location if there's enough offset
                let currentLocationOnAxis = ((position == .top) ? value.location.x : value.location.y)
                if draggingLastLocation == nil || abs(currentLocationOnAxis - draggingLastLocation!) >= 10 {
                    draggingLastLocation = currentLocationOnAxis
                }
            })
            .onEnded({ _ in
                draggingStartLocation = nil
                draggingLastLocation = nil
                withAnimation(.easeInOut(duration: 0.25)) {
                    tabOffsets = [:]
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    draggingTab = nil
                }
            })
    }
    
    private func initializeDragGesture(value: DragGesture.Value, for tab: Tab) {
        draggingTab = tab
        let initialLocation = position == .top ? value.startLocation.x : value.startLocation.y
        draggingStartLocation = initialLocation
        draggingLastLocation = initialLocation
    }
    
    private enum SwapDirection {
        case previous
        case next
    }
    
    private func swapTab(
        tab: Tab,
        currentIndex: Int,
        currentLocation: CGFloat,
        dragDifference: CGFloat,
        currentTabWidth: CGFloat,
        direction: SwapDirection
    ) {
        // Determine the index to swap with based on direction
        var swapIndex: Int?
        if direction == .previous {
            if currentIndex > 0 {
                swapIndex = currentIndex - 1
            }
        } else {
            if currentIndex < items.count - 1 {
                swapIndex = currentIndex + 1
            }
        }
        
        // Validate the drag direction
        let isValidDragDir = (direction == .previous && dragDifference < 0) ||
                            (direction == .next && dragDifference > 0)
        guard let swapIndex = swapIndex, isValidDragDir else { return }
        
        // Get info about the tab to swap with
        let swapTab = items[swapIndex]
        guard let swapTabLocation = tabLocations[swapTab],
              let swapTabWidth = tabWidth[swapTab]
        else { return }
        
        let isWithinBounds: Bool
        if position == .top {
            isWithinBounds = direction == .previous ?
                isWithinPrevTopBounds(currentLocation, swapTabLocation, swapTabWidth) :
                isWithinNextTopBounds(currentLocation, swapTabLocation, swapTabWidth, currentTabWidth)
        } else {
            isWithinBounds = direction == .previous ?
                isWithinPrevBottomBounds(currentLocation, swapTabLocation, swapTabWidth) :
                isWithinNextBottomBounds(currentLocation, swapTabLocation, swapTabWidth, currentTabWidth)
        }
        
        // Swap tab positions
        if isWithinBounds {
            let changing = swapTabWidth - 1
            draggingStartLocation! += direction == .previous ? -changing : changing
            tabOffsets[tab]! += direction == .previous ? changing : -changing
            items.swapAt(currentIndex, swapIndex)
        }
    }
    
    private func isWithinPrevTopBounds(
        _ curLocation: CGFloat,
        _ swapLocation: CGRect,
        _ swapWidth: CGFloat
    ) -> Bool {
        return curLocation < max(
            swapLocation.maxX - swapWidth * 0.1,
            swapLocation.minX + swapWidth * 0.9
        )
    }
    
    private func isWithinNextTopBounds(
        _ curLocation: CGFloat,
        _ swapLocation: CGRect,
        _ swapWidth: CGFloat,
        _ curWidth: CGFloat
    ) -> Bool {
        return curLocation > min(
            swapLocation.minX + swapWidth * 0.1,
            swapLocation.maxX - curWidth * 0.9
        )
    }
    
    private func isWithinPrevBottomBounds(
        _ curLocation: CGFloat,
        _ swapLocation: CGRect,
        _ swapWidth: CGFloat
    ) -> Bool {
        return curLocation < max(
            swapLocation.maxY - swapWidth * 0.1,
            swapLocation.minY + swapWidth * 0.9
        )
    }
    
    private func isWithinNextBottomBounds(
        _ curLocation: CGFloat,
        _ swapLocation: CGRect,
        _ swapWidth: CGFloat,
        _ curWidth: CGFloat
    ) -> Bool {
        return curLocation > min(
            swapLocation.minY + swapWidth * 0.1,
            swapLocation.maxY - curWidth * 0.9
        )
    }
    
    private func makeTabItemGeometryReader(tab: Tab) -> some View {
        GeometryReader { geometry in
            Rectangle()
                .foregroundColor(.clear)
                .onAppear {
                    self.tabWidth[tab] = (position == .top) ? geometry.size.width : geometry.size.height
                    self.tabLocations[tab] = geometry.frame(in: .global)
                }
                .onChange(of: geometry.frame(in: .global)) { newFrame in
                    self.tabLocations[tab] = newFrame
                }
                .onChange(of: geometry.size.width) { newWidth in
                    self.tabWidth[tab] = newWidth
                }
        }
    }
}
