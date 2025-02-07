// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Core",
    platforms: [
        .macOS(.v13),
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "Core",
            targets: ["Core", "Cgit2"]
        ),
    ],
    dependencies: [
        .package(path: "../Shared")
    ],
    targets: [
        .target(
            name: "Core",
            dependencies: [
                "Cgit2",
                "Shared"
            ],
            path: "Sources/Core",
            cSettings: [
                .headerSearchPath("../Cgit2/include"),
                .headerSearchPath("../../Libraries/libgit2/include")
            ],
            swiftSettings: [
                .unsafeFlags(["-Xfrontend", "-enable-implicit-dynamic"]),
                .define("SWIFT_PACKAGE")
            ],
            linkerSettings: [
                .unsafeFlags(["-force_load", "../../Libraries/libgit2/install/lib/libgit2.a"]),
                .linkedLibrary("iconv"),
                .linkedLibrary("z"),
                .linkedLibrary("git2"),
                .unsafeFlags(["-L../../Libraries/libgit2/install/lib"])
            ]
        ),
        .target(
            name: "Cgit2",
            path: "Sources/Cgit2",
            cSettings: [
                .headerSearchPath("."),
                .headerSearchPath("include"),
                .headerSearchPath("../../Libraries/libgit2/include")
            ],
            linkerSettings: [
                .unsafeFlags(["-L../../Libraries/libgit2/install/lib"]),
                .unsafeFlags(["-rpath", "../../Libraries/libgit2/install/lib"])
            ]
        ),
        .testTarget(
            name: "CoreTests",
            dependencies: ["Core"],
            path: "Tests/CoreTests"
        ),
    ]
)
