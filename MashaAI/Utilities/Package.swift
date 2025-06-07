// swift-tools-version: 5.9.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Utilities",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "Utilities",
            targets: ["Utilities"])
    ],
    dependencies: [
        .package(
            url: "https://github.com/onevcat/Kingfisher",
            from: "7.6.2"
        )
    ],
    targets: [
        .target(
            name: "Utilities",
            dependencies: [
                .product(name: "Kingfisher", package: "Kingfisher")
            ]
        ),
        .testTarget(
            name: "UtilitiesTests",
            dependencies: [
                "Utilities",
                "Kingfisher"
            ]
        )
    ]
)
