//
//  GitHubSetupCallback.swift
//  github-access-api
//
//  Created by Damian Van de Kauter on 09/10/2026.
//

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// The query GitHub appends when it redirects to a GitHub App's *setup URL* after someone installs,
/// updates or requests the App.
///
/// ```swift
/// let url = URL(string: "https://example.com/github/setup?installation_id=12345678&setup_action=install&state=abc")!
/// let callback = try GitHubSetupCallback(url: url)
///
/// callback.installationID // 12345678
/// callback.setupAction    // .install
/// callback.state          // "abc"
/// ```
///
/// It parses any URL with that query, so it reads the setup redirect itself as well as the
/// `<project>://github/setup-complete?installation_id=…` hop that github-access-vapor's setup page
/// forwards to an app.
///
/// ## The installation ID rule
///
/// `installation_id` must be a positive integer that fits in an `Int64` — the same rule as
/// github-access-vapor's `GET /github/setup` page (`Int64(raw)`, then `> 0`). Anything else is
/// rejected, because the ID ends up in HTML, URLs and database keys, and a non-numeric value reaching
/// any of them is an injection waiting to happen.
///
/// A missing ID is rejected too, with one exception: for `setup_action=request` — someone asked an
/// owner to install the App — no installation exists yet, so GitHub may send none. Only then is
/// ``installationID`` `nil`.
///
/// ## What this does not prove
///
/// The query is supplied by whoever opened the URL. A parsed callback says what the URL *claims*;
/// it proves nothing about who installed what. Check ``state`` against the value you issued, and
/// confirm the installation with GitHub (`GET /app/installations/{id}` with the App's JWT) before
/// trusting ``installationID``.
public struct GitHubSetupCallback: Codable, Sendable, Hashable {

    /// The installation that was created or updated. `nil` only when ``setupAction`` is
    /// ``GitHubSetupAction/request`` and GitHub sent no ID.
    public let installationID: Int64?

    /// Why GitHub redirected, or `nil` when the URL carries no `setup_action` (as the
    /// github-access-vapor app hop does not).
    public let setupAction: GitHubSetupAction?

    /// The `state` passed to ``GitHubInstallLink``, echoed back by GitHub. `nil` when absent or
    /// empty.
    ///
    /// Compare it to the value you issued, in constant time, and use it once: it is what ties this
    /// redirect to the person who started the install.
    public let state: String?

    /// Validates and stores the parts of a setup callback.
    ///
    /// - Parameters:
    ///   - installationID: The installation ID. Must be positive; may be `nil` only when
    ///     `setupAction` is ``GitHubSetupAction/request``.
    ///   - setupAction: Why GitHub redirected.
    ///   - state: The echoed `state`. An empty string is stored as `nil`.
    /// - Throws: ``GitHubSetupCallbackError/missingInstallationID`` or
    ///   ``GitHubSetupCallbackError/invalidInstallationID(_:)``.
    public init(
        installationID: Int64?,
        setupAction: GitHubSetupAction? = nil,
        state: String? = nil
    ) throws(GitHubSetupCallbackError) {
        if let installationID {
            guard installationID > 0 else {
                throw .invalidInstallationID(String(installationID))
            }
        } else if setupAction != .request {
            throw .missingInstallationID
        }

        self.installationID = installationID
        self.setupAction = setupAction
        self.state = state.flatMap { $0.isEmpty ? nil : $0 }
    }

    /// Parses the query of a setup redirect URL.
    ///
    /// - Parameter url: The URL GitHub redirected to, or the app-scheme URL it was forwarded to.
    /// - Throws: A ``GitHubSetupCallbackError`` describing the first problem found.
    public init(url: URL) throws(GitHubSetupCallbackError) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            throw .unreadableURL
        }
        try self.init(queryItems: components.queryItems ?? [])
    }

    /// Parses already-split query items, such as those a web framework hands a route.
    ///
    /// Unknown parameters are ignored. `installation_id`, `setup_action` and `state` may each
    /// appear at most once.
    ///
    /// - Parameter queryItems: The query items of the redirect.
    /// - Throws: A ``GitHubSetupCallbackError`` describing the first problem found.
    public init(queryItems: [URLQueryItem]) throws(GitHubSetupCallbackError) {
        let rawID = try Self.single("installation_id", in: queryItems)
        let rawAction = try Self.single("setup_action", in: queryItems)
        let rawState = try Self.single("state", in: queryItems)

        let action = rawAction.flatMap { $0.isEmpty ? nil : GitHubSetupAction(rawValue: $0) }

        let installationID: Int64?
        if let rawID {
            // Matches github-access-vapor's setup page exactly: Int64(raw), then > 0.
            guard let parsed = Int64(rawID), parsed > 0 else {
                throw .invalidInstallationID(rawID)
            }
            installationID = parsed
        } else {
            installationID = nil
        }

        try self.init(installationID: installationID, setupAction: action, state: rawState)
    }

    /// The value of a parameter that may appear at most once. A parameter written without a value
    /// (`?installation_id`) counts as absent.
    private static func single(_ name: String, in items: [URLQueryItem]) throws(GitHubSetupCallbackError) -> String? {
        let matches = items.filter { $0.name == name }
        guard matches.count <= 1 else { throw .duplicateParameter(name) }
        return matches.first?.value
    }

    private enum CodingKeys: String, CodingKey {
        case installationID = "installation_id"
        case setupAction = "setup_action"
        case state
    }

    /// Decodes `installation_id`, `setup_action` and `state`, applying the same validation as
    /// ``init(installationID:setupAction:state:)``.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        try self.init(
            installationID: try container.decodeIfPresent(Int64.self, forKey: .installationID),
            setupAction: try container.decodeIfPresent(GitHubSetupAction.self, forKey: .setupAction),
            state: try container.decodeIfPresent(String.self, forKey: .state)
        )
    }

    /// Encodes `installation_id`, `setup_action` and `state`, omitting absent ones.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encodeIfPresent(installationID, forKey: .installationID)
        try container.encodeIfPresent(setupAction, forKey: .setupAction)
        try container.encodeIfPresent(state, forKey: .state)
    }
}
