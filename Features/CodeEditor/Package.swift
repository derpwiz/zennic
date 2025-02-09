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
            targets: ["CodeEditorInterface"]
        ),
    ],
    dependencies: [
        .package(path: "../Core"),
        .package(path: "../Shared")
    ],
    targets: [
        .target(
            name: "CodeEditorInterface",
            dependencies: [
                .product(name: "Core", package: "Core"),
                .product(name: "Shared", package: "Shared")
            ],
            path: "Sources/CodeEditorInterface"
        ),
        .target(
            name: "CodeEditor",
            dependencies: [
                .product(name: "Core", package: "Core"),
                .product(name: "Shared", package: "Shared"),
                "CodeEditorInterface"
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
