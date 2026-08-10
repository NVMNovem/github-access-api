// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "github-access-api",
    platforms: [.macOS(.v14), .iOS(.v17), .watchOS(.v10), .tvOS(.v17), .visionOS(.v1)],
    products: [
        // Models and the read-only REST client. No dependencies, runs everywhere Foundation does.
        .library(name: "GitHubAccessCore", targets: ["GitHubAccessCore"]),

        // The SwiftUI onboarding flow. Apple platforms only; re-exports GitHubAccessCore.
        .library(name: "GitHubAccessAPI", targets: ["GitHubAccessAPI"]),
    ],
    targets: [
        // Must never gain a dependency: that constraint is what lets a Linux agent,
        // a CLI and an iOS app all link this target.
        .target(
            name: "GitHubAccessCore"
        ),
        .target(
            name: "GitHubAccessAPI",
            dependencies: ["GitHubAccessCore"]
        ),
        .testTarget(
            name: "GitHubAccessCoreTests",
            dependencies: ["GitHubAccessCore"]
        ),
        .testTarget(
            name: "GitHubAccessAPITests",
            dependencies: ["GitHubAccessAPI"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
