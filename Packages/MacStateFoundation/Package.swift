// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MacStateFoundation",
    platforms: [
        .macOS(.v11),
    ],
    products: [
        .library(
            name: "MacStateFoundation",
            targets: ["MacStateFoundation"]
        ),
    ],
    targets: [
        .target(
            name: "MacStateFoundation",
            linkerSettings: [
                .linkedFramework("ServiceManagement"),
            ]
        ),
        .testTarget(
            name: "MacStateFoundationTests",
            dependencies: ["MacStateFoundation"]
        ),
    ]
)
