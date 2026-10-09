//
//  GitHubRepositoryRef.swift
//  github-access-api
//
//  Created by Damian Van de Kauter on 09/10/2026.
//

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// A reference to a repository: enough to name it, link to it and clone it.
///
/// This is the shape of the entries in an `installation_repositories` webhook's
/// `repositories_added` / `repositories_removed` lists (`id`, `node_id`, `name`, `full_name`,
/// `private`). It also decodes the full repository objects returned by
/// `GET /installation/repositories` and embedded in webhooks, keeping the few extra fields a
/// deploy needs and ignoring the rest.
///
/// ``fullName`` is the only required field, so a reference can also be built from an
/// `owner/name` string someone typed:
///
/// ```swift
/// let repository = GitHubRepositoryRef(fullName: "octocat/Hello-World")
/// print(repository.owner) // "octocat"
/// ```
public struct GitHubRepositoryRef: Codable, Sendable, Hashable {

    /// The repository's numeric ID. Stable across renames and transfers, unlike ``fullName``, so it
    /// is the one to store.
    public var id: Int64?

    /// The GraphQL node ID.
    public var nodeID: String?

    /// The repository name without its owner, such as `Hello-World`.
    public var name: String

    /// `owner/name`, which is what a clone URL and most REST paths are built from.
    public var fullName: String

    /// Whether the repository is private. A clone then needs an installation token.
    public var isPrivate: Bool

    /// The repository's page on github.com.
    public var htmlURL: String?

    /// The HTTPS clone URL.
    public var cloneURL: String?

    /// The default branch, such as `main`.
    public var defaultBranch: String?

    /// The owner part of ``fullName``.
    public var owner: String {
        fullName.split(separator: "/", maxSplits: 1).first.map(String.init) ?? fullName
    }

    /// Creates a reference.
    ///
    /// - Parameters:
    ///   - id: The repository's numeric ID.
    ///   - nodeID: The GraphQL node ID.
    ///   - name: The repository name. Defaults to the part of `fullName` after the `/`.
    ///   - fullName: `owner/name`.
    ///   - isPrivate: Whether the repository is private.
    ///   - htmlURL: The repository's page on github.com.
    ///   - cloneURL: The HTTPS clone URL.
    ///   - defaultBranch: The default branch.
    public init(
        id: Int64? = nil,
        nodeID: String? = nil,
        name: String? = nil,
        fullName: String,
        isPrivate: Bool = false,
        htmlURL: String? = nil,
        cloneURL: String? = nil,
        defaultBranch: String? = nil
    ) {
        self.id = id
        self.nodeID = nodeID
        self.name = name ?? Self.name(from: fullName)
        self.fullName = fullName
        self.isPrivate = isPrivate
        self.htmlURL = htmlURL
        self.cloneURL = cloneURL
        self.defaultBranch = defaultBranch
    }

    private static func name(from fullName: String) -> String {
        fullName.split(separator: "/", maxSplits: 1).last.map(String.init) ?? fullName
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case nodeID = "node_id"
        case name
        case fullName = "full_name"
        case isPrivate = "private"
        case htmlURL = "html_url"
        case cloneURL = "clone_url"
        case defaultBranch = "default_branch"
    }

    /// Decodes a repository object. Only `full_name` is required; a missing `name` is taken from
    /// it and a missing `private` reads as `false`.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let fullName = try container.decode(String.self, forKey: .fullName)
        self.id = try container.decodeIfPresent(Int64.self, forKey: .id)
        self.nodeID = try container.decodeIfPresent(String.self, forKey: .nodeID)
        self.name = try container.decodeIfPresent(String.self, forKey: .name) ?? Self.name(from: fullName)
        self.fullName = fullName
        self.isPrivate = try container.decodeIfPresent(Bool.self, forKey: .isPrivate) ?? false
        self.htmlURL = try container.decodeIfPresent(String.self, forKey: .htmlURL)
        self.cloneURL = try container.decodeIfPresent(String.self, forKey: .cloneURL)
        self.defaultBranch = try container.decodeIfPresent(String.self, forKey: .defaultBranch)
    }

    /// Encodes with GitHub's snake_case keys, omitting absent fields.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encodeIfPresent(id, forKey: .id)
        try container.encodeIfPresent(nodeID, forKey: .nodeID)
        try container.encode(name, forKey: .name)
        try container.encode(fullName, forKey: .fullName)
        try container.encode(isPrivate, forKey: .isPrivate)
        try container.encodeIfPresent(htmlURL, forKey: .htmlURL)
        try container.encodeIfPresent(cloneURL, forKey: .cloneURL)
        try container.encodeIfPresent(defaultBranch, forKey: .defaultBranch)
    }
}
