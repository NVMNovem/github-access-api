// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "github-access-api",
    platforms: [.macOS(.v14), .iOS(.v17), .watchOS(.v10), .tvOS(.v17)],
    products: [
        .library(name: "GitHubAccessAPI", targets: ["GitHubAccessAPI"]),
    ],
    targets: [
        .target(
            name: "GitHubAccessAPI"
        ),
        .testTarget(
            name: "GitHubAccessAPITests",
            dependencies: ["GitHubAccessAPI"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
