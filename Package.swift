// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftMessageBar",
    platforms: [
        .iOS(.v12),
    ],
    products: [
        .library(
            name: "SwiftMessageBar",
            targets: ["SwiftMessageBar"]),
    ],
    targets: [
        .target(
            name: "SwiftMessageBar",
            path: "SwiftMessageBar",
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "SwiftMessageBarTests",
            dependencies: ["SwiftMessageBar"],
            path: "SwiftMessageBarTests"
        ),
    ]
)
