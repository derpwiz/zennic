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
            publicHeadersPath: "include",
            cSettings: [
                .headerSearchPath("../Cgit2/include"),
                .headerSearchPath("../Cgit2/include/git2"),
                .headerSearchPath("../Cgit2/include/git2/sys"),
                .headerSearchPath("../../Libraries/libgit2/include")
            ],
            swiftSettings: [
                .unsafeFlags(["-Xfrontend", "-enable-implicit-dynamic"]),
                .unsafeFlags(["-Xfrontend", "-disable-objc-attr-requires-foundation-module"]),
                .define("SWIFT_PACKAGE")
            ],
            linkerSettings: [
                .linkedLibrary("git2"),
                .linkedLibrary("iconv"),
                .linkedLibrary("z"),
                .unsafeFlags(["-L../../Libraries/libgit2/install/lib"])
            ]
        ),
        .target(
            name: "Cgit2",
            path: "Sources/Cgit2",
            publicHeadersPath: "include",
            cSettings: [
                .headerSearchPath("."),
                .headerSearchPath("include"),
                .headerSearchPath("include/git2"),
                .headerSearchPath("include/git2/sys"),
                .headerSearchPath("../../Libraries/libgit2/include")
            ],
            linkerSettings: [
                .linkedLibrary("git2"),
                .unsafeFlags(["-L../../Libraries/libgit2/install/lib"])
            ]
        ),
        .testTarget(
            name: "CoreTests",
            dependencies: ["Core"],
            path: "Tests/CoreTests"
        ),
    ]
)
