//
//  GitHubInstallation.swift
//  github-access-api
//
//  Created by Damian Van de Kauter on 09/10/2026.
//

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// An installation of a GitHub App on a user, organization or enterprise account.
///
/// Decodes the object returned by `GET /app/installations/{installation_id}` and embedded in
/// `installation` webhooks. The ``id`` is what an installation access token is minted for.
///
/// An installation can be suspended — by the account owner or by GitHub — without being removed.
/// While ``isSuspended`` is `true`, GitHub refuses to mint tokens for it, so a client should treat
/// it as connected but unusable rather than as gone.
public struct GitHubInstallation: Codable, Sendable, Hashable {

    /// The installation ID. Pass it to github-access-vapor to mint an installation token.
    public var id: Int64

    /// The account the App is installed on. GitHub documents it as nullable.
    public var account: GitHubAccount?

    /// Whether the installation reaches every repository of the account or only selected ones.
    public var repositorySelection: GitHubRepositorySelection?

    /// The ID of the App this is an installation of.
    public var appID: Int64?

    /// The slug of the App this is an installation of, as in `github.com/apps/<slug>`.
    public var appSlug: String?

    /// The ID of the account the App is installed on.
    public var targetID: Int64?

    /// The kind of account the App is installed on, such as `Organization`.
    public var targetType: GitHubAccountType?

    /// The permissions this installation granted, keyed by permission name (`contents`,
    /// `metadata`, …).
    ///
    /// This is what the installer *accepted*, which can lag behind what the App asks for: when an
    /// App requests a new permission, existing installations keep the old set until an owner
    /// approves the change.
    public var permissions: [String: GitHubPermissionLevel]

    /// The webhook events this installation delivers.
    public var events: [String]

    /// The installation's settings page on github.com.
    public var htmlURL: String?

    /// The REST endpoint that mints installation access tokens.
    public var accessTokensURL: String?

    /// The REST endpoint that lists the repositories the installation can reach.
    public var repositoriesURL: String?

    /// When the App was installed.
    public var createdAt: Date?

    /// When the installation last changed.
    public var updatedAt: Date?

    /// When the installation was suspended, or `nil` when it is active.
    public var suspendedAt: Date?

    /// Who suspended the installation, or `nil` when it is active.
    public var suspendedBy: GitHubAccount?

    /// Whether the installation is suspended. GitHub mints no tokens for a suspended installation.
    public var isSuspended: Bool { suspendedAt != nil }

    /// Creates an installation.
    ///
    /// - Parameters:
    ///   - id: The installation ID.
    ///   - account: The account the App is installed on.
    ///   - repositorySelection: Whether every or only selected repositories are reachable.
    ///   - appID: The App's ID.
    ///   - appSlug: The App's slug.
    ///   - targetID: The ID of the account the App is installed on.
    ///   - targetType: The kind of account the App is installed on.
    ///   - permissions: The permissions the installation granted.
    ///   - events: The webhook events the installation delivers.
    ///   - htmlURL: The installation's settings page.
    ///   - accessTokensURL: The token-minting endpoint.
    ///   - repositoriesURL: The repository-listing endpoint.
    ///   - createdAt: When the App was installed.
    ///   - updatedAt: When the installation last changed.
    ///   - suspendedAt: When the installation was suspended.
    ///   - suspendedBy: Who suspended the installation.
    public init(
        id: Int64,
        account: GitHubAccount? = nil,
        repositorySelection: GitHubRepositorySelection? = nil,
        appID: Int64? = nil,
        appSlug: String? = nil,
        targetID: Int64? = nil,
        targetType: GitHubAccountType? = nil,
        permissions: [String: GitHubPermissionLevel] = [:],
        events: [String] = [],
        htmlURL: String? = nil,
        accessTokensURL: String? = nil,
        repositoriesURL: String? = nil,
        createdAt: Date? = nil,
        updatedAt: Date? = nil,
        suspendedAt: Date? = nil,
        suspendedBy: GitHubAccount? = nil
    ) {
        self.id = id
        self.account = account
        self.repositorySelection = repositorySelection
        self.appID = appID
        self.appSlug = appSlug
        self.targetID = targetID
        self.targetType = targetType
        self.permissions = permissions
        self.events = events
        self.htmlURL = htmlURL
        self.accessTokensURL = accessTokensURL
        self.repositoriesURL = repositoriesURL
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.suspendedAt = suspendedAt
        self.suspendedBy = suspendedBy
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case account
        case repositorySelection = "repository_selection"
        case appID = "app_id"
        case appSlug = "app_slug"
        case targetID = "target_id"
        case targetType = "target_type"
        case permissions
        case events
        case htmlURL = "html_url"
        case accessTokensURL = "access_tokens_url"
        case repositoriesURL = "repositories_url"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case suspendedAt = "suspended_at"
        case suspendedBy = "suspended_by"
    }

    /// Decodes GitHub's installation object. Only `id` is required; timestamps are read as ISO 8601
    /// strings whatever the decoder's date strategy.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try container.decode(Int64.self, forKey: .id)
        self.account = try container.decodeIfPresent(GitHubAccount.self, forKey: .account)
        self.repositorySelection = try container.decodeIfPresent(GitHubRepositorySelection.self, forKey: .repositorySelection)
        self.appID = try container.decodeIfPresent(Int64.self, forKey: .appID)
        self.appSlug = try container.decodeIfPresent(String.self, forKey: .appSlug)
        self.targetID = try container.decodeIfPresent(Int64.self, forKey: .targetID)
        self.targetType = try container.decodeIfPresent(GitHubAccountType.self, forKey: .targetType)
        self.permissions = try container.decodeIfPresent([String: GitHubPermissionLevel].self, forKey: .permissions) ?? [:]
        self.events = try container.decodeIfPresent([String].self, forKey: .events) ?? []
        self.htmlURL = try container.decodeIfPresent(String.self, forKey: .htmlURL)
        self.accessTokensURL = try container.decodeIfPresent(String.self, forKey: .accessTokensURL)
        self.repositoriesURL = try container.decodeIfPresent(String.self, forKey: .repositoriesURL)
        self.createdAt = try container.decodeGitHubDateIfPresent(forKey: .createdAt)
        self.updatedAt = try container.decodeGitHubDateIfPresent(forKey: .updatedAt)
        self.suspendedAt = try container.decodeGitHubDateIfPresent(forKey: .suspendedAt)
        self.suspendedBy = try container.decodeIfPresent(GitHubAccount.self, forKey: .suspendedBy)
    }

    /// Encodes with GitHub's snake_case keys and ISO 8601 timestamps, omitting absent fields.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(account, forKey: .account)
        try container.encodeIfPresent(repositorySelection, forKey: .repositorySelection)
        try container.encodeIfPresent(appID, forKey: .appID)
        try container.encodeIfPresent(appSlug, forKey: .appSlug)
        try container.encodeIfPresent(targetID, forKey: .targetID)
        try container.encodeIfPresent(targetType, forKey: .targetType)
        try container.encode(permissions, forKey: .permissions)
        try container.encode(events, forKey: .events)
        try container.encodeIfPresent(htmlURL, forKey: .htmlURL)
        try container.encodeIfPresent(accessTokensURL, forKey: .accessTokensURL)
        try container.encodeIfPresent(repositoriesURL, forKey: .repositoriesURL)
        try container.encodeGitHubDateIfPresent(createdAt, forKey: .createdAt)
        try container.encodeGitHubDateIfPresent(updatedAt, forKey: .updatedAt)
        try container.encodeGitHubDateIfPresent(suspendedAt, forKey: .suspendedAt)
        try container.encodeIfPresent(suspendedBy, forKey: .suspendedBy)
    }
}
