// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MacStateUI",
    platforms: [
        .macOS(.v11),
    ],
    products: [
        .library(
            name: "MacStateUI",
            targets: ["MacStateUI"]
        ),
    ],
    dependencies: [
        .package(path: "../MacStateFoundation"),
    ],
    targets: [
        .target(
            name: "MacStateUI",
            dependencies: [
                .product(name: "MacStateFoundation", package: "MacStateFoundation"),
            ]
        ),
        .testTarget(
            name: "MacStateUITests",
            dependencies: ["MacStateUI"]
        ),
    ]
)
