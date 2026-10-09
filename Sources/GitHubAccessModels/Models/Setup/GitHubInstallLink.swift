//
//  GitHubInstallLink.swift
//  github-access-api
//
//  Created by Damian Van de Kauter on 09/10/2026.
//

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// The link that starts installing a GitHub App:
/// `https://github.com/apps/<slug>/installations/new?state=<token>`.
///
/// ```swift
/// let link = try GitHubInstallLink(appSlug: "funico-server-manager", state: "k7Q+/x")
/// link.url // https://github.com/apps/funico-server-manager/installations/new?state=k7Q%2B%2Fx
/// ```
///
/// Open it in a browser (or `ASWebAuthenticationSession`, or a plain redirect from a web page).
/// After the person picks an account and repositories, GitHub redirects to the App's setup URL with
/// the same `state`, which ``GitHubSetupCallback`` reads back.
///
/// The slug goes into the URL path, so it is validated — letters, digits, `-` and `_` only — and an
/// invalid one throws instead of being encoded. The state goes into the query and may be any
/// string: every character outside RFC 3986's unreserved set is percent-encoded, including `+`,
/// which a form decoder would otherwise read back as a space.
///
/// Issue a fresh, unguessable, single-use `state` for every link, and bind it to the person who asked
/// for it. Without one, the setup redirect cannot be told apart from a forged one.
public struct GitHubInstallLink: Sendable, Hashable, CustomStringConvertible {

    /// The App's slug, as in `github.com/apps/<slug>`.
    public let appSlug: String

    /// The opaque value GitHub echoes back on the setup redirect, or `nil` for a link without one.
    public let state: String?

    /// The install link.
    public let url: URL

    /// Builds an install link.
    ///
    /// - Parameters:
    ///   - appSlug: The App's slug. Letters, digits, `-` and `_` only.
    ///   - state: The value GitHub should echo back. An empty string is treated as `nil`.
    /// - Throws: ``GitHubLinkError/invalidAppSlug(_:)`` when the slug is unsafe to place in a path.
    public init(appSlug: String, state: String? = nil) throws(GitHubLinkError) {
        guard GitHubIdentifier.isValidSlug(appSlug) else {
            throw .invalidAppSlug(appSlug)
        }

        let state = state.flatMap { $0.isEmpty ? nil : $0 }
        var string = "https://github.com/apps/\(appSlug)/installations/new"
        if let state {
            string += "?state=" + PercentEncoding.encode(state)
        }

        // Every character is now either validated or percent-encoded, so this cannot fail.
        guard let url = URL(string: string) else {
            throw .invalidAppSlug(appSlug)
        }

        self.appSlug = appSlug
        self.state = state
        self.url = url
    }

    /// The link as a string.
    public var description: String { url.absoluteString }
}
