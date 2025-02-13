//
//  SidebarNavigationView.swift
//  Documents
//
//  Created by Claude on 2/11/25.
//

import SwiftUI

/// The sidebar navigation view showing available features.
public struct SidebarNavigationView: View {
    @Binding private var selectedFeature: String?

    public init(selectedFeature: Binding<String?>) {
        self._selectedFeature = selectedFeature
    }

    public var body: some View {
        List(selection: $selectedFeature) {
            NavigationLink(
                destination: EmptyView(),
                tag: "CodeEditor",
                selection: $selectedFeature
            ) {
                Label("Code Editor", systemImage: "doc.text")
            }

            NavigationLink(
                destination: EmptyView(),
                tag: "RealTimeMonitoring",
                selection: $selectedFeature
            ) {
                Label("Real-Time Monitoring", systemImage: "chart.line.uptrend.xyaxis")
            }

            NavigationLink(
                destination: EmptyView(),
                tag: "Backtesting",
                selection: $selectedFeature
            ) {
                Label("Backtesting", systemImage: "clock.arrow.circlepath")
            }

            NavigationLink(
                destination: EmptyView(),
                tag: "Visualization",
                selection: $selectedFeature
            ) {
                Label("Visualization", systemImage: "chart.bar")
            }

            NavigationLink(
                destination: EmptyView(),
                tag: "DataIntegration",
                selection: $selectedFeature
            ) {
                Label("Data Integration", systemImage: "network")
            }
        }
        .listStyle(.sidebar)
    }
}
