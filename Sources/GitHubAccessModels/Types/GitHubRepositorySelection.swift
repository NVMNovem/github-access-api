//
//  GitHubRepositorySelection.swift
//  github-access-api
//
//  Created by Damian Van de Kauter on 09/10/2026.
//

/// Which repositories an installation can reach.
///
/// An open type, so a value GitHub adds later still decodes.
public struct GitHubRepositorySelection: RawRepresentable, Hashable, Sendable, Codable, ExpressibleByStringLiteral, CustomStringConvertible {

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

    /// Every repository the account owns, including ones created after installation.
    public static let all: GitHubRepositorySelection = "all"

    /// Only the repositories the installer picked. They are listed by `GET /installation/repositories`.
    public static let selected: GitHubRepositorySelection = "selected"
}
