<picture>
  <source srcset="https://github.com/user-attachments/assets/38817448-f9ae-47cd-9e37-34292f9f1746" media="(prefers-color-scheme: light)"/>
  <source srcset="https://github.com/user-attachments/assets/b1dd11dd-98cf-402b-bc11-de31b73302e0"  media="(prefers-color-scheme: dark)"/>
  <img src="https://github.com/user-attachments/assets/38817448-f9ae-47cd-9e37-34292f9f1746" alt="GitHubAccessAPI"/>
</picture>

GitHubAccessAPI is a Swift package for integrating GitHub App setup and installation-token generation into Vapor projects.

It provides a lightweight API to interact with a GitHub access server, with optional SwiftUI setup flows for client-side integration.

## Platform Compatibility
This Swift package is designed to run on:
- ![macOS](https://github.com/NVMNovem/github-access-api/actions/workflows/buildOnMacOS.yml/badge.svg)
- ![Linux](https://github.com/NVMNovem/github-access-api/actions/workflows/buildOnLinux.yml/badge.svg)

## Installation

Add `github-access-api` as a dependency to your `Package.swift`:

```swift
// Package.swift (snippet)
dependencies: [
    .package(url: "https://github.com/NVMNovem/github-access-api", from: "1.0.0")
]

targets: [
    .target(
        name: "MyApp",
        dependencies: [
            .product(name: "GitHubAccessAPI", package: "github-access-api")
        ]
    )
]
```

## Basic usage

#### SwiftUI ViewModifier
```swift
import GitHubAccess

struct ContentView: View {
    var body: some View {
        MainView()
            .gitHubSetup { result in
                switch result {
                case .success(let installationId):
                    print("Installation ID:", installationId)
                case .failure(let error):
                    print("Setup failed:", error)
                }
            }
    }
}
```

#### SwiftUI Scene

Use this when working with `DocumentGroup` scenes.

```swift
import GitHubAccess

@main
struct MyApp: App {
    var body: some Scene {
        DocumentGroup(newDocument: MyDocument()) { file in
            DocumentView(document: file.$document)
        }

        GitHubSetup { result in
            switch result {
            case .success(let installationId):
                print("Installation ID:", installationId)
            case .failure(let error):
                print("Setup failed:", error)
            }
        }
    }
}
```
