// swift-tools-version: 5.9.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Networking",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "Networking",
            targets: ["Networking"]
        )
    ],
    dependencies: [
        .package(name: "Logger", path: "../Logger"),
        .package(name: "Utilities", path: "../Utilities")
    ],
    targets: [
        .target(
            name: "Networking",
            dependencies: [
                "Logger",
                "Utilities"
            ]
        )
    ]
)
