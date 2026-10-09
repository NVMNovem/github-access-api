//
//  GitHubAccountType.swift
//  github-access-api
//
//  Created by Damian Van de Kauter on 09/10/2026.
//

/// The `type` of a GitHub account: a user, an organization, a bot or an enterprise.
///
/// An open type rather than an enum: GitHub has added account types before, and an unrecognised one
/// must not turn an installation or a release into a decoding failure. Compare against the
/// constants; anything else survives a round trip unchanged.
public struct GitHubAccountType: RawRepresentable, Hashable, Sendable, Codable, ExpressibleByStringLiteral, CustomStringConvertible {

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

    /// A personal account.
    public static let user: GitHubAccountType = "User"

    /// An organization. Installing on one usually takes an organization owner.
    public static let organization: GitHubAccountType = "Organization"

    /// A bot account, such as a GitHub App's `<slug>[bot]` user.
    public static let bot: GitHubAccountType = "Bot"

    /// An enterprise. Its account object carries a `slug` and `name` instead of a `login`.
    public static let enterprise: GitHubAccountType = "Enterprise"
}
