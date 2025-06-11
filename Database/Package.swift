// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Database",
    products: [
        .library(
            name: "Database",
            targets: ["Database"]
        )
    ],
    dependencies: [
        .package(name: "Utilities", path: "../Utilities")
    ],
    targets: [
        .target(
            name: "Database",
            dependencies: [
                "Utilities"
            ]
        )
    ]
)
