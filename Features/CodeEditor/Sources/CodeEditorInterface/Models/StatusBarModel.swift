//
//  StatusBarModel.swift
//  CodeEditorInterface
//
//  Created by Claude on 2/11/25.
//

import Foundation

public struct StatusBarModel {
    public let fileSize: Int?
    public let line: Int
    public let column: Int
    public let characterOffset: Int
    public let selectedLength: Int
    public let selectedLines: Int
    
    public init(fileSize: Int?, line: Int, column: Int, characterOffset: Int, selectedLength: Int, selectedLines: Int) {
        self.fileSize = fileSize
        self.line = line
        self.column = column
        self.characterOffset = characterOffset
        self.selectedLength = selectedLength
        self.selectedLines = selectedLines
    }
}
