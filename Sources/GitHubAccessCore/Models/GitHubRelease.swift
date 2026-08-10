//
//  GitHubRelease.swift
//  github-access-api
//

import Foundation

/// A published release of a repository.
///
/// Decodes the payload GitHub returns from `GET /repos/{owner}/{repo}/releases`
/// and `GET /repos/{owner}/{repo}/releases/latest`.
public struct GitHubRelease: Sendable, Codable, Hashable, Identifiable {

    /// GitHub's numeric release identifier.
    public let id: Int64

    /// The git tag the release points at, for example `2.1.0`.
    public let tagName: String

    /// The human-readable release title, if the author set one.
    public let name: String?

    /// Whether the release is still a draft and therefore not publicly visible.
    public let isDraft: Bool

    /// Whether the release is marked as a pre-release.
    public let isPrerelease: Bool

    /// When the release was published. `nil` for drafts.
    public let publishedAt: Date?

    /// Binaries attached to the release.
    ///
    /// Empty for releases that ship source only.
    public let assets: [GitHubReleaseAsset]

    public init(
        id: Int64,
        tagName: String,
        name: String?,
        isDraft: Bool,
        isPrerelease: Bool,
        publishedAt: Date?,
        assets: [GitHubReleaseAsset]
    ) {
        self.id = id
        self.tagName = tagName
        self.name = name
        self.isDraft = isDraft
        self.isPrerelease = isPrerelease
        self.publishedAt = publishedAt
        self.assets = assets
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case tagName = "tag_name"
        case name
        case isDraft = "draft"
        case isPrerelease = "prerelease"
        case publishedAt = "published_at"
        case assets
    }
}
