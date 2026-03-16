// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MacStateStorage",
    platforms: [
        .macOS(.v11),
    ],
    products: [
        .library(
            name: "MacStateStorage",
            targets: ["MacStateStorage"]
        ),
    ],
    dependencies: [
        .package(path: "../MacStateFoundation"),
        .package(path: "../MacStateMetrics"),
    ],
    targets: [
        .target(
            name: "MacStateStorage",
            dependencies: [
                .product(name: "MacStateFoundation", package: "MacStateFoundation"),
                .product(name: "MacStateMetrics", package: "MacStateMetrics"),
            ]
        ),
        .testTarget(
            name: "MacStateStorageTests",
            dependencies: [
                "MacStateStorage",
                .product(name: "MacStateMetrics", package: "MacStateMetrics"),
            ]
        ),
    ]
)
