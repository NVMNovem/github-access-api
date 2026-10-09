//
//  GitHubPermissionLevel.swift
//  github-access-api
//
//  Created by Damian Van de Kauter on 09/10/2026.
//

/// The access a GitHub App holds on one permission, such as `contents` or `metadata`.
///
/// Used both for what an installation was granted (`GitHubInstallation/permissions`) and for
/// what an App manifest asks for (`GitHubAppManifest/defaultPermissions`). An open type, so a
/// level GitHub adds later still decodes.
public struct GitHubPermissionLevel: RawRepresentable, Hashable, Sendable, Codable, ExpressibleByStringLiteral, CustomStringConvertible {

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

    /// Read-only access.
    public static let read: GitHubPermissionLevel = "read"

    /// Read and write access.
    public static let write: GitHubPermissionLevel = "write"

    /// Administrative access. Rarely needed, and never by the Server Manager.
    public static let admin: GitHubPermissionLevel = "admin"
}
