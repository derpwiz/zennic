// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "AIHedgeFund",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "AIHedgeFund",
            targets: ["AIHedgeFund"]),
    ],
    dependencies: [
        .package(url: "https://github.com/danielgindi/Charts.git", from: "5.0.0")
    ],
    targets: [
        .target(
            name: "AIHedgeFund",
            dependencies: [
                .product(name: "Charts", package: "Charts")
            ],
            path: "AIHedgeFund",
            resources: [
                .process("Resources")
            ]),
        .testTarget(
            name: "AIHedgeFundTests",
            dependencies: ["AIHedgeFund"],
            path: "AIHedgeFundTests"),
    ],
    swiftLanguageVersions: [.v5]
)
