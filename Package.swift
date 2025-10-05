// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ComicsGenerator",
    platforms: [
        .macOS(.v14),
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "ComicsGenerator",
            targets: ["ComicsGenerator"]
        )
    ],
    dependencies: [
        // YAML parsing for asset.yaml and history.yaml
        .package(url: "https://github.com/jpsim/Yams.git", from: "5.0.0")
    ],
    targets: [
        .target(
            name: "ComicsGenerator",
            dependencies: ["Yams"]
        ),
        .testTarget(
            name: "ComicsGeneratorTests",
            dependencies: ["ComicsGenerator"]
        )
    ]
)
