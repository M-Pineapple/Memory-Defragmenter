// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MemoryDefragmenter",
    platforms: [
        .macOS(.v15) // macOS Sequoia for Xcode 26
    ],
    products: [
        .library(
            name: "MemoryDefragmenter",
            targets: ["MemoryDefragmenter"]),
    ],
    dependencies: [
        // SQLite wrapper for Swift
        .package(url: "https://github.com/stephencelis/SQLite.swift.git", from: "0.15.0"),
        
        // Python bridge for embeddings
        .package(url: "https://github.com/pvieito/PythonKit.git", branch: "master"),
        
        // Argument parser for CLI support
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.3.0"),
    ],
    targets: [
        .target(
            name: "MemoryDefragmenter",
            dependencies: [
                .product(name: "SQLite", package: "SQLite.swift"),
                "PythonKit",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ],
            swiftSettings: [
                // Swift 6 features
                .enableExperimentalFeature("StrictConcurrency"),
                .enableExperimentalFeature("GlobalActorIsolation"),
            ]
        ),
        .testTarget(
            name: "MemoryDefragmenterTests",
            dependencies: ["MemoryDefragmenter"]),
    ]
)
