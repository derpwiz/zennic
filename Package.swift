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
        .package(url: "https://github.com/danielgindi/Charts.git", .upToNextMajor(from: "5.0.0"))
    ],
    targets: [
        .target(
            name: "AIHedgeFund",
            dependencies: [
                .product(name: "DGCharts", package: "Charts")
            ],
            path: "AIHedgeFund"),
        .testTarget(
            name: "AIHedgeFundTests",
            dependencies: ["AIHedgeFund"],
            path: "AIHedgeFundTests"),
    ],
    swiftLanguageVersions: [.v5]
)
