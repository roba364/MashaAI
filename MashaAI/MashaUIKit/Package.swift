// swift-tools-version: 5.9.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MashaUIKit",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "MashaUIKit",
            targets: ["MashaUIKit"]
        )
    ],
    dependencies: [
        .package(name: "Utilities", path: "../Utilities")
    ],
    targets: [
        .target(
            name: "MashaUIKit",
            dependencies: [
                "Utilities"
            ]
        )
    ]
)
