// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ManuallyOrderable",
    platforms: [.macOS(.v14), .iOS(.v17), .tvOS(.v17), .watchOS(.v10)],
    products: [
        .library(
            name: "ManuallyOrderable",
            targets: ["ManuallyOrderable"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-collections.git", from: "1.1.3")
    ],
    targets: [
        .target(
            name: "ManuallyOrderable",
            dependencies: [
                .product(name: "OrderedCollections", package: "swift-collections")
            ]),
        .testTarget(
            name: "ManuallyOrderableTests",
            dependencies: ["ManuallyOrderable"]
        ),
    ]
)
