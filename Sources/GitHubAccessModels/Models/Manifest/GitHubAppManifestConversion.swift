//
//  GitHubAppManifestConversion.swift
//  github-access-api
//
//  Created by Damian Van de Kauter on 09/10/2026.
//

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// The App GitHub created from a ``GitHubAppManifest``: the response to
/// `POST /app-manifests/{code}/conversions`.
///
/// > Warning: **This response carries the App's secrets.** ``pem`` is the App's private key —
/// > whoever holds it can act as the App on every account it is installed on. ``clientSecret`` and
/// > ``webhookSecret`` are secrets too. GitHub shows them exactly once, here.
/// >
/// > Hand the value straight to a secret store, and never log it, return it to a client, persist it
/// > as plain JSON, or send it anywhere it does not have to go. Its `debugDescription` and
/// > `customMirror` — what `print`, string interpolation and `dump` fall back to — redact the
/// > secrets, but encoding it — `Codable` — writes them out in full, as it must for a
/// > secret store to receive them.
///
/// The exchange is the server's job: the `code` is single use and expires after an hour, and only
/// the server should ever see the result.
public struct GitHubAppManifestConversion: Codable, Sendable, Hashable, CustomDebugStringConvertible, CustomReflectable {

    /// The new App's ID — what an App JWT names as its issuer.
    public var id: Int64

    /// The App's slug, as in `github.com/apps/<slug>`. Build install links from it with
    /// ``GitHubInstallLink``.
    public var slug: String

    /// The GraphQL node ID.
    public var nodeID: String?

    /// The App's name, possibly changed by the administrator on GitHub's review page.
    public var name: String?

    /// The App's description.
    ///
    /// This is GitHub's `description` field, which is why the type is not
    /// `CustomStringConvertible`; `print` and interpolation use the redacted ``debugDescription``.
    public var description: String?

    /// The account that owns the App.
    public var owner: GitHubAccount?

    /// The App's homepage, from the manifest's `url`.
    public var externalURL: String?

    /// The App's page on github.com.
    public var htmlURL: String?

    /// When the App was created.
    public var createdAt: Date?

    /// When the App last changed.
    public var updatedAt: Date?

    /// The permissions the App was created with.
    public var permissions: [String: GitHubPermissionLevel]

    /// The webhook events the App subscribes to.
    public var events: [String]

    /// The OAuth client ID. Not secret on its own.
    public var clientID: String

    /// **Secret.** The OAuth client secret.
    public var clientSecret: String

    /// **Secret.** The secret GitHub signs webhook deliveries with, or `nil` when the App has no
    /// webhook.
    public var webhookSecret: String?

    /// **Secret.** The App's private key, PEM-encoded. Signs the JWTs that mint installation tokens.
    public var pem: String

    /// Creates a conversion response.
    ///
    /// - Parameters:
    ///   - id: The App's ID.
    ///   - slug: The App's slug.
    ///   - nodeID: The GraphQL node ID.
    ///   - name: The App's name.
    ///   - description: The App's description.
    ///   - owner: The account that owns the App.
    ///   - externalURL: The App's homepage.
    ///   - htmlURL: The App's page on github.com.
    ///   - createdAt: When the App was created.
    ///   - updatedAt: When the App last changed.
    ///   - permissions: The App's permissions.
    ///   - events: The App's webhook events.
    ///   - clientID: The OAuth client ID.
    ///   - clientSecret: The OAuth client secret.
    ///   - webhookSecret: The webhook signing secret.
    ///   - pem: The App's private key.
    public init(
        id: Int64,
        slug: String,
        nodeID: String? = nil,
        name: String? = nil,
        description: String? = nil,
        owner: GitHubAccount? = nil,
        externalURL: String? = nil,
        htmlURL: String? = nil,
        createdAt: Date? = nil,
        updatedAt: Date? = nil,
        permissions: [String: GitHubPermissionLevel] = [:],
        events: [String] = [],
        clientID: String,
        clientSecret: String,
        webhookSecret: String?,
        pem: String
    ) {
        self.id = id
        self.slug = slug
        self.nodeID = nodeID
        self.name = name
        self.description = description
        self.owner = owner
        self.externalURL = externalURL
        self.htmlURL = htmlURL
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.permissions = permissions
        self.events = events
        self.clientID = clientID
        self.clientSecret = clientSecret
        self.webhookSecret = webhookSecret
        self.pem = pem
    }

    // MARK: Redaction

    private var redactedSummary: String {
        "GitHubAppManifestConversion(id: \(id), slug: \"\(slug)\", clientID: \"\(clientID)\", "
            + "clientSecret: <redacted>, webhookSecret: \(webhookSecret == nil ? "nil" : "<redacted>"), pem: <redacted>)"
    }

    /// A summary that names the App and redacts its secrets.
    public var debugDescription: String { redactedSummary }

    /// The mirror `dump` and the debugger use. The secrets are replaced with `<redacted>`.
    public var customMirror: Mirror {
        Mirror(self, children: [
            "id": id,
            "slug": slug,
            "name": name as Any,
            "owner": owner as Any,
            "clientID": clientID,
            "clientSecret": "<redacted>",
            "webhookSecret": webhookSecret == nil ? "nil" : "<redacted>",
            "pem": "<redacted>",
        ], displayStyle: .struct)
    }

    // MARK: Codable

    private enum CodingKeys: String, CodingKey {
        case id
        case slug
        case nodeID = "node_id"
        case name
        case description
        case owner
        case externalURL = "external_url"
        case htmlURL = "html_url"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case permissions
        case events
        case clientID = "client_id"
        case clientSecret = "client_secret"
        case webhookSecret = "webhook_secret"
        case pem
    }

    /// Decodes GitHub's conversion response. `id`, `slug`, `client_id`, `client_secret` and `pem`
    /// are required: a response without them has not created a usable App.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try container.decode(Int64.self, forKey: .id)
        self.slug = try container.decode(String.self, forKey: .slug)
        self.nodeID = try container.decodeIfPresent(String.self, forKey: .nodeID)
        self.name = try container.decodeIfPresent(String.self, forKey: .name)
        self.description = try container.decodeIfPresent(String.self, forKey: .description)
        self.owner = try container.decodeIfPresent(GitHubAccount.self, forKey: .owner)
        self.externalURL = try container.decodeIfPresent(String.self, forKey: .externalURL)
        self.htmlURL = try container.decodeIfPresent(String.self, forKey: .htmlURL)
        self.createdAt = try container.decodeGitHubDateIfPresent(forKey: .createdAt)
        self.updatedAt = try container.decodeGitHubDateIfPresent(forKey: .updatedAt)
        self.permissions = try container.decodeIfPresent([String: GitHubPermissionLevel].self, forKey: .permissions) ?? [:]
        self.events = try container.decodeIfPresent([String].self, forKey: .events) ?? []
        self.clientID = try container.decode(String.self, forKey: .clientID)
        self.clientSecret = try container.decode(String.self, forKey: .clientSecret)
        self.webhookSecret = try container.decodeIfPresent(String.self, forKey: .webhookSecret)
        self.pem = try container.decode(String.self, forKey: .pem)
    }

    /// Encodes every field, **secrets included**, with GitHub's snake_case keys. Only encode this
    /// into a secret store.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(id, forKey: .id)
        try container.encode(slug, forKey: .slug)
        try container.encodeIfPresent(nodeID, forKey: .nodeID)
        try container.encodeIfPresent(name, forKey: .name)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encodeIfPresent(owner, forKey: .owner)
        try container.encodeIfPresent(externalURL, forKey: .externalURL)
        try container.encodeIfPresent(htmlURL, forKey: .htmlURL)
        try container.encodeGitHubDateIfPresent(createdAt, forKey: .createdAt)
        try container.encodeGitHubDateIfPresent(updatedAt, forKey: .updatedAt)
        try container.encode(permissions, forKey: .permissions)
        try container.encode(events, forKey: .events)
        try container.encode(clientID, forKey: .clientID)
        try container.encode(clientSecret, forKey: .clientSecret)
        try container.encodeIfPresent(webhookSecret, forKey: .webhookSecret)
        try container.encode(pem, forKey: .pem)
    }
}
