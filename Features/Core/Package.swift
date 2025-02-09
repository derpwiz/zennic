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
        .package(path: "../Shared"),
        .package(path: "../UI")
    ],
    targets: [
        .target(
            name: "Core",
            dependencies: [
                "Cgit2",
                "Shared",
                "UI"
            ],
            path: "Sources/Core",
            exclude: ["include/Core-Swift.h"],
            publicHeadersPath: "include",
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
                .linkedLibrary("git2"),
                .linkedLibrary("System"),
                .linkedLibrary("iconv"),
                .linkedLibrary("z"),
                .linkedFramework("Security"),
                .linkedFramework("GSS"),
                .linkedFramework("CoreFoundation"),
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
                .unsafeFlags(["-force_load", "../../Libraries/libgit2/install/lib/libgit2.a"]),
                .linkedLibrary("git2"),
                .linkedLibrary("System"),
                .linkedLibrary("iconv"),
                .linkedLibrary("z"),
                .linkedFramework("Security"),
                .linkedFramework("GSS"),
                .linkedFramework("CoreFoundation"),
                .unsafeFlags(["-L../../Libraries/libgit2/install/lib"]),
                .unsafeFlags(["-rpath", "../../Libraries/libgit2/install/lib"])
            ]
        ),
        .testTarget(
            name: "CoreTests",
            dependencies: ["Core"],
            path: "Tests"
        ),
    ]
)
