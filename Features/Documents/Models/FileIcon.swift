//
//  FileIcon.swift
//  zennic
//
//  Created by Claude on 2/11/25.
//

import SwiftUI

enum FileIcon {
    enum FileType: String {
        case swift
        case js
        case ts
        case jsx
        case tsx
        case json
        case md
        case txt
        case html
        case css
        case py
        case go
        case rs
        case cpp
        case c
        case h
        case hpp
        case java
        case kt
        case rb
        case php
        case sh
        case yaml
        case toml
        case xml
        case pdf
        case jpg
        case png
        case gif
        case svg
        case mp4
        case mp3
        case wav
        case zip
        case tar
        case gz
        case _7z
        case dmg
        case iso
        case pkg
        case app
        case exe
        case dll
        case other
    }

    static func fileIcon(fileType: FileType) -> String {
        switch fileType {
        case .swift: return "swift"
        case .js, .jsx: return "js"
        case .ts, .tsx: return "ts"
        case .json: return "curlybraces"
        case .md: return "doc.text"
        case .txt: return "doc.text"
        case .html: return "chevron.left.forwardslash.chevron.right"
        case .css: return "number"
        case .py: return "doc.text"
        case .go: return "doc.text"
        case .rs: return "doc.text"
        case .cpp, .c, .h, .hpp: return "doc.text"
        case .java: return "doc.text"
        case .kt: return "doc.text"
        case .rb: return "doc.text"
        case .php: return "doc.text"
        case .sh: return "terminal"
        case .yaml, .toml: return "doc.text"
        case .xml: return "chevron.left.forwardslash.chevron.right"
        case .pdf: return "doc.text"
        case .jpg, .png, .gif, .svg: return "photo"
        case .mp4: return "video"
        case .mp3, .wav: return "music.note"
        case .zip, .tar, .gz, ._7z: return "doc.zipper"
        case .dmg, .iso, .pkg: return "externaldrive"
        case .app, .exe, .dll: return "app.badge"
        case .other: return "doc"
        }
    }

    static func iconColor(fileType: FileType) -> Color {
        switch fileType {
        case .swift: return .orange
        case .js, .jsx: return .yellow
        case .ts, .tsx: return .blue
        case .json: return .purple
        case .md: return .gray
        case .txt: return .gray
        case .html: return .red
        case .css: return .blue
        case .py: return .green
        case .go: return .blue
        case .rs: return .orange
        case .cpp, .c, .h, .hpp: return .blue
        case .java: return .orange
        case .kt: return .purple
        case .rb: return .red
        case .php: return .purple
        case .sh: return .gray
        case .yaml, .toml: return .blue
        case .xml: return .orange
        case .pdf: return .red
        case .jpg, .png, .gif, .svg: return .blue
        case .mp4: return .purple
        case .mp3, .wav: return .pink
        case .zip, .tar, .gz, ._7z: return .gray
        case .dmg, .iso, .pkg: return .gray
        case .app, .exe, .dll: return .blue
        case .other: return .gray
        }
    }
}
