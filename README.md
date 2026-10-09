<picture>
  <source srcset="https://github.com/user-attachments/assets/38817448-f9ae-47cd-9e37-34292f9f1746" media="(prefers-color-scheme: light)"/>
  <source srcset="https://github.com/user-attachments/assets/b1dd11dd-98cf-402b-bc11-de31b73302e0"  media="(prefers-color-scheme: dark)"/>
  <img src="https://github.com/user-attachments/assets/38817448-f9ae-47cd-9e37-34292f9f1746" alt="GitHubAccessAPI"/>
</picture>

GitHubAccessAPI is the client half of connecting a GitHub App: the models and links that start and
finish an installation, and a SwiftUI flow that catches the installation when GitHub sends the user
back. Its server half is [github-access-vapor](https://github.com/NVMNovem/github-access-vapor).

It ships two products:

| Product | Platforms | What it is |
|---|---|---|
| `GitHubAccessModels` | Linux, macOS, iOS, watchOS, tvOS, wasm | `Codable` models with no dependency beyond Foundation (`FoundationEssentials` where available): installations, repositories, releases and assets, the setup callback, the install link, and the App manifest |
| `GitHubAccessAPI` | Apple platforms with SwiftUI | The `.gitHubSetup {}` modifier and `GitHubSetup` scene, built on the models. Re-exports `GitHubAccessModels`; on Linux it contains only the models and `SetupError`/`SetupResult` |

## Platform Compatibility
This Swift package is designed to run on:
- ![macOS](https://github.com/NVMNovem/github-access-api/actions/workflows/buildOnMacOS.yml/badge.svg)
- ![Linux](https://github.com/NVMNovem/github-access-api/actions/workflows/buildOnLinux.yml/badge.svg)

## Installation

Add `github-access-api` as a dependency to your `Package.swift`:

```swift
// Package.swift (snippet)
dependencies: [
    .package(url: "https://github.com/NVMNovem/github-access-api", from: "1.1.0")
]

targets: [
    // An app using the SwiftUI flow:
    .target(
        name: "MyApp",
        dependencies: [
            .product(name: "GitHubAccessAPI", package: "github-access-api")
        ]
    ),
    // A server, CLI or wasm client that only needs the models:
    .target(
        name: "MyService",
        dependencies: [
            .product(name: "GitHubAccessModels", package: "github-access-api")
        ]
    )
]
```

## GitHubAccessModels

### Installing an App: the link out and the callback back

Send the user to GitHub with a fresh, single-use `state`, and read the installation back from the
setup redirect:

```swift
import Foundation
import GitHubAccessModels

// 1. Start the installation. Bind `state` to the signed-in user and keep it until they return.
let state = UUID().uuidString
let link = try GitHubInstallLink(appSlug: "funico-server-manager", state: state)
print(link.url)
// https://github.com/apps/funico-server-manager/installations/new?state=…

// 2. GitHub redirects to the App's setup URL with installation_id, setup_action and the state.
let redirect = URL(string: "https://manager.example.com/github/setup?installation_id=12345678&setup_action=install&state=\(state)")!
let callback = try GitHubSetupCallback(url: redirect)

guard callback.state == state else {
    fatalError("Not the installation this user started.")
}

if let installationID = callback.installationID {
    print("Installed:", installationID, callback.setupAction ?? .install)
} else {
    print("Installation requested; an owner still has to approve it.")
}
```

`GitHubSetupCallback` rejects a missing, non-numeric or non-positive `installation_id` — the same
rule as github-access-vapor's setup page — and a duplicated parameter. A parsed callback is still
only what the URL *claims*: check the `state`, and confirm the installation with GitHub
(`GET /app/installations/{id}`) before trusting it.

### Releases

`GitHubRelease` and `GitHubReleaseAsset` decode GitHub's REST and webhook JSON with any
`JSONDecoder` — timestamps are read as ISO 8601 whatever the decoder's date strategy:

```swift
import Foundation
import GitHubAccessModels

let json = Data("""
{
  "tag_name": "v1.2.0",
  "draft": false,
  "prerelease": false,
  "published_at": "2026-10-01T09:30:00Z",
  "assets": [
    { "name": "server-linux-x86_64.tar.gz", "size": 1048576, "state": "uploaded" }
  ]
}
""".utf8)

let release = try JSONDecoder().decode(GitHubRelease.self, from: json)
let deployable = !release.draft && !release.prerelease

for asset in release.assets where asset.state == "uploaded" {
    print(release.tagName, asset.name, asset.size ?? 0, deployable)
}
```

`GitHubInstallation`, `GitHubRepositoryRef` and `GitHubAccount` decode the matching REST objects the
same way.

### Creating the App from a manifest

Instead of filling in GitHub's form by hand, an administrator can register the App in one step. The
`serverManager` preset asks for the least the Funico Server Manager needs — `contents: read`,
`metadata: read`, and `release` events:

```swift
import Foundation
import GitHubAccessModels

let manifest = GitHubAppManifest.serverManager(
    name: "Funico Server Manager",
    url: URL(string: "https://manager.example.com")!,
    webhookURL: URL(string: "https://manager.example.com/github/webhook")!,
    redirectURL: URL(string: "https://manager.example.com/github/manifest/callback")!,
    setupURL: URL(string: "https://manager.example.com/github/setup")!
)

let registration = try manifest.registration(for: .organization("funico"), state: UUID().uuidString)

// The browser POSTs this form to GitHub; GitHub only accepts it from a signed-in administrator.
print(registration.url)                 // https://github.com/organizations/funico/settings/apps/new?state=…
print(registration.formURLEncodedBody)  // manifest=%7B%22default_events%22…
```

GitHub then redirects to `redirectURL` with a `code`, which the server exchanges with
`POST /app-manifests/{code}/conversions`. The answer decodes as `GitHubAppManifestConversion` and
**carries the App's private key, client secret and webhook secret** — hand it straight to a secret
store and never log it or return it to a client. Its `print` and `dump` output redact the secrets,
but encoding it writes them in full.

## GitHubAccessAPI (SwiftUI)

`import GitHubAccessAPI` also imports `GitHubAccessModels`.

#### SwiftUI ViewModifier
```swift
import SwiftUI
import GitHubAccessAPI

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
import SwiftUI
import GitHubAccessAPI

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

Both catch the URL the app is opened with — such as the `<project>://github/setup-complete?installation_id=…`
hop github-access-vapor's setup page forwards to — and parse it with `GitHubSetupCallback`. A
missing, non-numeric or non-positive `installation_id` reports `SetupError.invalidInstallationID`.
