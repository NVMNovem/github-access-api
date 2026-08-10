//
//  GitHubRepository.swift
//  github-access-api
//

import Foundation

/// A repository visible to a GitHub App installation.
///
/// Decodes the repository payload GitHub returns from
/// `GET /installation/repositories` and `GET /repos/{owner}/{repo}`.
public struct GitHubRepository: Sendable, Codable, Hashable, Identifiable {

    /// GitHub's numeric repository identifier.
    public let id: Int64

    /// The repository name without its owner, for example `funico-invoices-service`.
    public let name: String

    /// The owner-qualified name, for example `Funico-NV/funico-invoices-service`.
    public let fullName: String

    /// The login of the user or organisation that owns the repository.
    ///
    /// GitHub sends this nested inside an `owner` object; it is flattened to the login here.
    public let owner: String

    /// Whether the repository is private.
    public let isPrivate: Bool

    /// The branch GitHub considers the default, for example `main`.
    public let defaultBranch: String

    /// The HTTPS clone URL.
    public let cloneURL: URL

    /// The URL of the repository page on github.com.
    public let htmlURL: URL

    public init(
        id: Int64,
        name: String,
        fullName: String,
        owner: String,
        isPrivate: Bool,
        defaultBranch: String,
        cloneURL: URL,
        htmlURL: URL
    ) {
        self.id = id
        self.name = name
        self.fullName = fullName
        self.owner = owner
        self.isPrivate = isPrivate
        self.defaultBranch = defaultBranch
        self.cloneURL = cloneURL
        self.htmlURL = htmlURL
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case fullName = "full_name"
        case owner
        case isPrivate = "private"
        case defaultBranch = "default_branch"
        case cloneURL = "clone_url"
        case htmlURL = "html_url"
    }

    /// The shape GitHub uses for `owner`. Only the login is kept.
    private struct Owner: Codable {
        let login: String
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try container.decode(Int64.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        self.fullName = try container.decode(String.self, forKey: .fullName)

        // GitHub nests the owner; a bare string is accepted too so that values encoded
        // by an older build, or hand-written fixtures, still decode.
        if let owner = try? container.decode(Owner.self, forKey: .owner) {
            self.owner = owner.login
        } else {
            self.owner = try container.decode(String.self, forKey: .owner)
        }

        self.isPrivate = try container.decode(Bool.self, forKey: .isPrivate)
        self.defaultBranch = try container.decode(String.self, forKey: .defaultBranch)
        self.cloneURL = try container.decode(URL.self, forKey: .cloneURL)
        self.htmlURL = try container.decode(URL.self, forKey: .htmlURL)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(self.id, forKey: .id)
        try container.encode(self.name, forKey: .name)
        try container.encode(self.fullName, forKey: .fullName)
        try container.encode(Owner(login: self.owner), forKey: .owner)
        try container.encode(self.isPrivate, forKey: .isPrivate)
        try container.encode(self.defaultBranch, forKey: .defaultBranch)
        try container.encode(self.cloneURL, forKey: .cloneURL)
        try container.encode(self.htmlURL, forKey: .htmlURL)
    }
}
