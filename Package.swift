// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Gitsune",
    platforms: [
        .macOS(.v12),
        .iOS(.v15),
        .tvOS(.v15),
        .watchOS(.v8),
        .macCatalyst(.v15),
        .visionOS(.v1),
        .driverKit(.v21),
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "Gitsune",
            targets: ["Gitsune"]),
    ],
    dependencies: [
        .package(url: "https://github.com/bdewey/static-libgit2.git", from: "0.5.0"),
        .package(url: "https://github.com/RougeWare/Swift-Simple-Logging.git", from: "0.5.2"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "Gitsune",
            dependencies: [
                "static-libgit2",
                .product(name: "SimpleLogging", package: "Swift-Simple-Logging"),
            ]),
        .testTarget(
            name: "GitsuneTests",
            dependencies: ["Gitsune"]
        ),
    ]
)
