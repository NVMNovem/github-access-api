//
//  SetupGroup.swift
//  github-access-vapor
//
//  Created by Damian Van de Kauter on 17/04/2026.
//

#if canImport(SwiftUI)
import SwiftUI

/// A window scene that finishes a GitHub App installation when the app is opened with the setup
/// URL, such as `<project>://github/setup-complete?installation_id=…`.
///
/// Use it instead of the `gitHubSetup(setup:)` view modifier when the app's scenes are
/// `DocumentGroup`s, which do not deliver URLs to `onOpenURL` on their content.
///
/// The URL is parsed with `GitHubSetupCallback`. The scene shows progress, reports the result,
/// and closes its window shortly after a success.
public struct GitHubSetup: Scene {
    private static let windowId = "setup"
    
    private let setup: ((Result<Int, Error>) -> Void)?
    @State private var incomingURL: URL?
    @State private var setupResult: SetupResult?
    
    /// Creates the scene.
    ///
    /// - Parameter setup: Called once with the installation ID, or with the error that stopped the
    ///   setup.
    public init(setup: @escaping (Result<Int, Error>) -> Void) {
        self.setup = setup
    }
    
    /// Creates the scene without a result handler. The window still shows the setup's progress.
    public init() {
        self.setup = nil
    }
    
    /// The setup window.
    public var body: some Scene {
        WindowGroup(id: GitHubSetup.windowId) {
            SetupView(setup, incomingURL: $incomingURL, setupResult: $setupResult, windowId: GitHubSetup.windowId)
                .onOpenURL { url in
                    incomingURL = url
                }
        }
    }
}
#endif
