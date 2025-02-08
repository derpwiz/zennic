// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "UI",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "UI",
            targets: ["UI"]
        ),
    ],
    dependencies: [
        .package(path: "../Core"),
        .package(path: "../Shared"),
        .package(path: "../CodeEditor")
    ],
    targets: [
        .target(
            name: "UI",
            dependencies: [
                .product(name: "Core", package: "Core"),
                "Shared",
                .product(name: "CodeEditorInterface", package: "CodeEditor")
            ],
            path: "Sources"
        )
    ]
)
