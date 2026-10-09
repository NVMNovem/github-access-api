// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "github-access-api",
    platforms: [.macOS(.v14), .iOS(.v17), .watchOS(.v10), .tvOS(.v17)],
    products: [
        // The SwiftUI setup flow. Re-exports GitHubAccessModels.
        .library(name: "GitHubAccessAPI", targets: ["GitHubAccessAPI"]),
        // Platform-neutral GitHub App models: Linux, Apple platforms and wasm. Foundation only.
        .library(name: "GitHubAccessModels", targets: ["GitHubAccessModels"]),
    ],
    targets: [
        .target(
            name: "GitHubAccessModels"
        ),
        .target(
            name: "GitHubAccessAPI",
            dependencies: ["GitHubAccessModels"]
        ),
        .testTarget(
            name: "GitHubAccessModelsTests",
            dependencies: ["GitHubAccessModels"]
        ),
        .testTarget(
            name: "GitHubAccessAPITests",
            dependencies: ["GitHubAccessAPI"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
