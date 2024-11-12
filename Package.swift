// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "JPackage",
    products: [
        .library(
            name: "JPackage",
            type: .dynamic,
            targets: ["JPackage"]),
    ],
    dependencies: [
        .package(url: "https://github.com/JordanHaer/JDependency", branch: "main"),
    ],
    targets: [
        .target(
            name: "JPackage",
            dependencies: [
                .product(name: "JDependency", package: "JDependency")
            ]
        ),
        .testTarget(
            name: "JPackageTests",
            dependencies: ["JPackage"]
        ),
    ]
)
