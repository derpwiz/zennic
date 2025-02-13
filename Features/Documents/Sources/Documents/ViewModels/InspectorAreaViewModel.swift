//
//  InspectorAreaViewModel.swift
//  zennic
//

import SwiftUI

final class InspectorAreaViewModel: ObservableObject {
    enum InspectorTab: Int, CaseIterable {
        case file
        case history
        
        var title: String {
            switch self {
            case .file:
                return "File Inspector"
            case .history:
                return "History"
            }
        }
        
        var systemImage: String {
            switch self {
            case .file:
                return "doc.text"
            case .history:
                return "clock"
            }
        }
    }
    
    @Published var selectedTab: InspectorTab = .file
    @Published var isCollapsed: Bool = true
    
    // File inspector state
    @Published var fileInfo: [String: String] = [:]
    
    // History inspector state
    @Published var historyItems: [String] = []
    
    init() {}
    
    func updateFileInfo(_ info: [String: String]) {
        fileInfo = info
    }
    
    func updateHistory(_ items: [String]) {
        historyItems = items
    }
}
