//
//  GitHubSetupAction.swift
//  github-access-api
//
//  Created by Damian Van de Kauter on 09/10/2026.
//

/// Why GitHub redirected to an App's setup URL: the `setup_action` query parameter.
///
/// An open type, so an action GitHub adds later is passed through rather than rejected.
public struct GitHubSetupAction: RawRepresentable, Hashable, Sendable, Codable, ExpressibleByStringLiteral, CustomStringConvertible {

    /// The string GitHub sends.
    public let rawValue: String

    /// Wraps any value GitHub sends, including one this package has no constant for.
    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    /// Wraps any value GitHub sends, including one this package has no constant for.
    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    /// Wraps a string literal.
    public init(stringLiteral value: String) {
        self.rawValue = value
    }

    /// The raw value.
    public var description: String { rawValue }

    /// The App was just installed. The redirect carries the new `installation_id`.
    public static let install: GitHubSetupAction = "install"

    /// An existing installation changed, for example its repository selection. Sent only when the App has *Redirect on update* (`setup_on_update`) enabled.
    public static let update: GitHubSetupAction = "update"

    /// Someone without the right to install the App asked an owner to install it. No installation exists yet, so the redirect may carry no `installation_id`.
    public static let request: GitHubSetupAction = "request"
}
