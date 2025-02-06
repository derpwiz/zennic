// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Shared",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "Shared",
            targets: ["Shared"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "Shared",
            dependencies: [],
            path: "Sources",
            swiftSettings: [
                .define("SWIFT_PACKAGE", .when(configuration: .debug)),
                .unsafeFlags(["-enable-objc-interop"])
            ]
        )
    ]
)
