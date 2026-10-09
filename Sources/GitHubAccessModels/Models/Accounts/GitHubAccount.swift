//
//  GitHubAccount.swift
//  github-access-api
//
//  Created by Damian Van de Kauter on 09/10/2026.
//

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// A GitHub account — a user, an organization, a bot or an enterprise — as it appears inside an
/// installation, a release's `author`, or an asset's `uploader`.
///
/// Users, organizations and bots are identified by ``login``. An enterprise account has no login:
/// GitHub sends a ``slug`` and a ``name`` instead, which is why ``login`` is optional. Use
/// ``handle`` when you only need something to show.
///
/// Only the fields useful for identifying and linking to the account are modelled; the many `*_url`
/// API links GitHub also sends are ignored on decode.
public struct GitHubAccount: Codable, Sendable, Hashable {

    /// The account's numeric ID. Stable across renames, unlike ``login``.
    public var id: Int64?

    /// The GraphQL node ID.
    public var nodeID: String?

    /// The user or organization name, as in `github.com/<login>`. `nil` for an enterprise.
    public var login: String?

    /// The enterprise slug. Present only on enterprise accounts.
    public var slug: String?

    /// The enterprise's display name. Present only on enterprise accounts.
    public var name: String?

    /// What kind of account this is. GitHub omits it on enterprise accounts.
    public var type: GitHubAccountType?

    /// The account's page on github.com.
    public var htmlURL: String?

    /// The account's avatar image.
    public var avatarURL: String?

    /// ``login`` for users and organizations, ``slug`` for enterprises.
    public var handle: String? { login ?? slug }

    /// Creates an account.
    ///
    /// - Parameters:
    ///   - id: The account's numeric ID.
    ///   - nodeID: The GraphQL node ID.
    ///   - login: The user or organization login. `nil` for an enterprise.
    ///   - slug: The enterprise slug.
    ///   - name: The enterprise's display name.
    ///   - type: What kind of account this is.
    ///   - htmlURL: The account's page on github.com.
    ///   - avatarURL: The account's avatar image.
    public init(
        id: Int64? = nil,
        nodeID: String? = nil,
        login: String? = nil,
        slug: String? = nil,
        name: String? = nil,
        type: GitHubAccountType? = nil,
        htmlURL: String? = nil,
        avatarURL: String? = nil
    ) {
        self.id = id
        self.nodeID = nodeID
        self.login = login
        self.slug = slug
        self.name = name
        self.type = type
        self.htmlURL = htmlURL
        self.avatarURL = avatarURL
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case nodeID = "node_id"
        case login
        case slug
        case name
        case type
        case htmlURL = "html_url"
        case avatarURL = "avatar_url"
    }

    /// Decodes GitHub's snake_case account object. Every field is optional.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try container.decodeIfPresent(Int64.self, forKey: .id)
        self.nodeID = try container.decodeIfPresent(String.self, forKey: .nodeID)
        self.login = try container.decodeIfPresent(String.self, forKey: .login)
        self.slug = try container.decodeIfPresent(String.self, forKey: .slug)
        self.name = try container.decodeIfPresent(String.self, forKey: .name)
        self.type = try container.decodeIfPresent(GitHubAccountType.self, forKey: .type)
        self.htmlURL = try container.decodeIfPresent(String.self, forKey: .htmlURL)
        self.avatarURL = try container.decodeIfPresent(String.self, forKey: .avatarURL)
    }

    /// Encodes with GitHub's snake_case keys, omitting absent fields.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encodeIfPresent(id, forKey: .id)
        try container.encodeIfPresent(nodeID, forKey: .nodeID)
        try container.encodeIfPresent(login, forKey: .login)
        try container.encodeIfPresent(slug, forKey: .slug)
        try container.encodeIfPresent(name, forKey: .name)
        try container.encodeIfPresent(type, forKey: .type)
        try container.encodeIfPresent(htmlURL, forKey: .htmlURL)
        try container.encodeIfPresent(avatarURL, forKey: .avatarURL)
    }
}
