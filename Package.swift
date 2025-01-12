// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "AIHedgeFund",
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
        // Dependencies here
    ],
    targets: [
        .target(
            name: "AIHedgeFund",
            dependencies: [],
            path: "AIHedgeFund"),
        .testTarget(
            name: "AIHedgeFundTests",
            dependencies: ["AIHedgeFund"],
            path: "AIHedgeFundTests"),
    ]
)
