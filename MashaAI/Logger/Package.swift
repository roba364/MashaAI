// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Logger",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "Logger",
            targets: ["Logger"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/kean/Pulse", branch: "main")
    ],
    targets: [
        .target(
            name: "Logger",
            dependencies: [
                .product(name: "Pulse", package: "Pulse")
            ]
        )
    ]
)
