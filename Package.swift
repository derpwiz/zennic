// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "zennic",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "zennic",
            targets: ["zennic"]),
    ],
    dependencies: [
        .package(url: "https://github.com/danielgindi/Charts.git", exact: "5.0.0")
    ],
    targets: [
        .target(
            name: "zennic",
            dependencies: [
                .product(name: "DGCharts", package: "Charts", condition: .when(platforms: [.macOS]))
            ],
            path: "AIHedgeFund",
            exclude: ["Resources"]),
        .testTarget(
            name: "zennicTests",
            dependencies: ["zennic"],
            path: "AIHedgeFundTests"),
    ],
    swiftLanguageVersions: [.v5]
)
