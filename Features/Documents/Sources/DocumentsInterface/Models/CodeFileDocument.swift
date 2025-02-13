//
//  CodeFileDocument.swift
//  DocumentsInterface
//
//  Created by Claude on 2/11/25.
//

import AppKit
import UniformTypeIdentifiers

/// A document controller for code files.
public final class CodeEditDocumentController: NSDocumentController {
    public static override var shared: CodeEditDocumentController {
        return NSDocumentController.shared as! CodeEditDocumentController
    }

    private override init() {
        super.init()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// A document representing a code file.
public final class CodeFileDocument: NSDocument {
    public override init() {
        super.init()
    }

    public override func makeWindowControllers() {}

    public override func read(from url: URL, ofType typeName: String) throws {}

    public override func write(to url: URL, ofType typeName: String) throws {}
}

extension URL {
    /// The content type of the file at this URL.
    public var contentType: UTType? {
        (try? resourceValues(forKeys: [.contentTypeKey]))?.contentType
    }
}
