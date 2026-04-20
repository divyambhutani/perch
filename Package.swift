// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Perch",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "PerchApp", targets: ["PerchApp"]),
        .library(name: "Perch", targets: ["Perch"])
    ],
    dependencies: [
        .package(url: "https://github.com/groue/GRDB.swift.git", from: "7.0.0"),
        .package(url: "https://github.com/sparkle-project/Sparkle.git", from: "2.7.1"),
        .package(url: "https://github.com/sindresorhus/KeyboardShortcuts.git", from: "2.4.0"),
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing.git", from: "1.17.0")
    ],
    targets: [
        .target(
            name: "Perch",
            dependencies: [
                .product(name: "GRDB", package: "GRDB.swift"),
                .product(name: "Sparkle", package: "Sparkle"),
                .product(name: "KeyboardShortcuts", package: "KeyboardShortcuts")
            ],
            path: "Sources/Perch",
            resources: [
                .process("Resources"),
                .copy("../../Support/CLAUDE.md")
            ],
            swiftSettings: [
                .unsafeFlags(["-strict-concurrency=complete"])
            ]
        ),
        .executableTarget(
            name: "PerchApp",
            dependencies: ["Perch"],
            path: "Sources/PerchApp",
            swiftSettings: [
                .unsafeFlags(["-strict-concurrency=complete"])
            ]
        ),
        .testTarget(
            name: "PerchCoreTests",
            dependencies: [
                "Perch",
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing")
            ],
            path: "Tests/PerchCoreTests",
            swiftSettings: [
                .unsafeFlags(["-strict-concurrency=complete"])
            ]
        ),
        .testTarget(
            name: "PerchFeaturesTests",
            dependencies: ["Perch"],
            path: "Tests/PerchFeaturesTests",
            swiftSettings: [
                .unsafeFlags(["-strict-concurrency=complete"])
            ]
        )
    ]
)
