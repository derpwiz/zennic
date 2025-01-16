// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "AIHedgeFund",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v16),
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "AIHedgeFund",
            targets: ["AIHedgeFund"]),
    ],
    dependencies: [
        .package(url: "https://github.com/danielgindi/Charts.git", exact: "5.0.0")
    ],
    targets: [
        .target(
            name: "AIHedgeFund",
            dependencies: [
                .product(name: "DGCharts", package: "Charts", condition: .when(platforms: [.iOS]))
            ],
            path: "AIHedgeFund",
            exclude: ["Resources"]),
        .testTarget(
            name: "AIHedgeFundTests",
            dependencies: ["AIHedgeFund"],
            path: "AIHedgeFundTests"),
    ],
    swiftLanguageVersions: [.v5]
)
