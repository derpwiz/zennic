// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "CodeEditor",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "CodeEditor",
            targets: ["CodeEditor"]
        ),
    ],
    dependencies: [
        .package(path: "../Shared"),
        .package(path: "../Core"),
        .package(path: "../UI")
    ],
    targets: [
        .target(
            name: "CodeEditor",
            dependencies: [
                "Shared",
                .product(name: "Core", package: "Core"),
                .product(name: "UI", package: "UI")
            ],
            path: "Sources"
        )
    ]
)
