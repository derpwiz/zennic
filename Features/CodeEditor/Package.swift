// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "CodeEditor",
    platforms: [
        .macOS(.v13),
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "CodeEditor",
            targets: ["CodeEditor"]
        ),
        .library(
            name: "CodeEditorInterface",
            type: .dynamic,
            targets: ["CodeEditorInterface", "CodeEditor"]
        ),
    ],
    dependencies: [
        // Core module contains GitWrapper and other shared functionality
        .package(path: "../Core")
    ],
    targets: [
        .target(
            name: "CodeEditorInterface",
            dependencies: [
                .product(name: "Core", package: "Core"),
                "CodeEditor"
            ],
            path: "Sources/CodeEditorInterface"
        ),
        .target(
            name: "CodeEditor",
            dependencies: [
                .product(name: "Core", package: "Core")
            ],
            path: "Sources/CodeEditor"
        ),
        .testTarget(
            name: "CodeEditorTests",
            dependencies: ["CodeEditor"],
            path: "Tests/CodeEditor"
        ),
    ]
)
