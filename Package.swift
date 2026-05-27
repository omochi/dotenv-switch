// swift-tools-version: 6.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "dotenv-switch",
    platforms: [
        .macOS(.v10_15),
    ],
    products: [
        .executable(name: "dotenv-switch", targets: ["dotenv-switch"]),
        .library(name: "DESCore", targets: ["DESCore"]),
        .library(name: "DESCommands", targets: ["DESCommands"]),
    ],
    dependencies: [
        .package(url: "https://github.com/jpsim/Yams.git", from: "6.2.1"),
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.8.0"),
    ],
    targets: [
        .target(
            name: "DESCore",
            dependencies: [
                .product(name: "Yams", package: "Yams"),
            ]
        ),
        .executableTarget(
            name: "dotenv-switch",
            dependencies: [
                .target(name: "DESCommands"),
            ]
        ),
        .target(
            name: "DESCommands",
            dependencies: [
                .target(name: "DESCore"),
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
        .testTarget(
            name: "DotEnvSwitchTests",
            dependencies: [
                .target(name: "DESCore"),
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)
