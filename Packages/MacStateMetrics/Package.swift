// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MacStateMetrics",
    platforms: [
        .macOS(.v11),
    ],
    products: [
        .library(
            name: "MacStateMetrics",
            targets: ["MacStateMetrics"]
        ),
    ],
    dependencies: [
        .package(path: "../MacStateFoundation"),
    ],
    targets: [
        .target(
            name: "MacStateMetrics",
            dependencies: [
                .product(name: "MacStateFoundation", package: "MacStateFoundation"),
            ],
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("IOKit"),
            ]
        ),
        .testTarget(
            name: "MacStateMetricsTests",
            dependencies: ["MacStateMetrics"]
        ),
    ]
)
