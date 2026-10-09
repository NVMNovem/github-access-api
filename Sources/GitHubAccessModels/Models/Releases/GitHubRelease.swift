//
//  GitHubRelease.swift
//  github-access-api
//
//  Created by Damian Van de Kauter on 09/10/2026.
//

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// A release, as returned by GitHub's REST API (`GET /repos/{owner}/{repo}/releases…`) and
/// embedded in `release` webhooks.
///
/// Field names and JSON keys follow GitHub's REST API. This type replaces github-access-vapor's own
/// `GitHubRelease`: every property and initializer parameter that one has keeps its name, type and
/// position here, and the extra fields are appended with defaults, so the server and its clients
/// can share one definition without either losing data.
///
/// Only ``tagName`` is required. Everything else is optional or defaulted, so a payload GitHub has
/// since extended — or trimmed — still decodes.
///
/// A draft release is visible only to collaborators with push access and has no ``publishedAt``;
/// a deploy should normally skip both drafts and prereleases unless asked otherwise.
public struct GitHubRelease: Codable, Sendable, Hashable {

    /// The release's numeric ID.
    public var id: Int64?

    /// The git tag the release points at, such as `v1.0.0`. The one field GitHub always sends.
    public var tagName: String

    /// The release title. GitHub sends `null` when none was set; fall back to ``tagName``.
    public var name: String?

    /// The release notes, as Markdown.
    public var body: String?

    /// The branch or commit the tag was created from, when GitHub created the tag.
    public var targetCommitish: String?

    /// Whether this is an unpublished draft. Defaults to `false` when absent.
    public var draft: Bool

    /// Whether the release is marked as a prerelease. Defaults to `false` when absent.
    public var prerelease: Bool

    /// The release's page on github.com.
    public var htmlURL: String?

    /// The REST endpoint for a tarball of the tagged source.
    public var tarballURL: String?

    /// The REST endpoint for a zipball of the tagged source.
    public var zipballURL: String?

    /// When the release was created. For a tag pushed before the release, this is the tag's commit
    /// date, not when the release was drafted.
    public var createdAt: Date?

    /// When the release was published, or `nil` for a draft.
    public var publishedAt: Date?

    /// The files attached to the release. Empty when GitHub sends none.
    public var assets: [GitHubReleaseAsset]

    /// The GraphQL node ID.
    public var nodeID: String?

    /// The release's REST endpoint.
    public var url: String?

    /// The REST endpoint that lists the release's assets.
    public var assetsURL: String?

    /// The URI template assets are uploaded to, such as
    /// `https://uploads.github.com/…/assets{?name,label}`.
    public var uploadURL: String?

    /// Who created the release.
    public var author: GitHubAccount?

    /// Creates a release.
    ///
    /// The parameters up to `assets` match github-access-vapor's `GitHubRelease` initializer in name
    /// and order, so existing call sites keep compiling.
    ///
    /// - Parameters:
    ///   - id: The release's numeric ID.
    ///   - tagName: The git tag the release points at.
    ///   - name: The release title.
    ///   - body: The release notes.
    ///   - targetCommitish: The branch or commit the tag was created from.
    ///   - draft: Whether this is an unpublished draft.
    ///   - prerelease: Whether the release is marked as a prerelease.
    ///   - htmlURL: The release's page on github.com.
    ///   - tarballURL: The source tarball endpoint.
    ///   - zipballURL: The source zipball endpoint.
    ///   - createdAt: When the release was created.
    ///   - publishedAt: When the release was published.
    ///   - assets: The files attached to the release.
    ///   - nodeID: The GraphQL node ID.
    ///   - url: The release's REST endpoint.
    ///   - assetsURL: The asset-listing endpoint.
    ///   - uploadURL: The asset-upload URI template.
    ///   - author: Who created the release.
    public init(
        id: Int64? = nil,
        tagName: String,
        name: String? = nil,
        body: String? = nil,
        targetCommitish: String? = nil,
        draft: Bool = false,
        prerelease: Bool = false,
        htmlURL: String? = nil,
        tarballURL: String? = nil,
        zipballURL: String? = nil,
        createdAt: Date? = nil,
        publishedAt: Date? = nil,
        assets: [GitHubReleaseAsset] = [],
        nodeID: String? = nil,
        url: String? = nil,
        assetsURL: String? = nil,
        uploadURL: String? = nil,
        author: GitHubAccount? = nil
    ) {
        self.id = id
        self.tagName = tagName
        self.name = name
        self.body = body
        self.targetCommitish = targetCommitish
        self.draft = draft
        self.prerelease = prerelease
        self.htmlURL = htmlURL
        self.tarballURL = tarballURL
        self.zipballURL = zipballURL
        self.createdAt = createdAt
        self.publishedAt = publishedAt
        self.assets = assets
        self.nodeID = nodeID
        self.url = url
        self.assetsURL = assetsURL
        self.uploadURL = uploadURL
        self.author = author
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case tagName = "tag_name"
        case name
        case body
        case targetCommitish = "target_commitish"
        case draft
        case prerelease
        case htmlURL = "html_url"
        case tarballURL = "tarball_url"
        case zipballURL = "zipball_url"
        case createdAt = "created_at"
        case publishedAt = "published_at"
        case assets
        case nodeID = "node_id"
        case url
        case assetsURL = "assets_url"
        case uploadURL = "upload_url"
        case author
    }

    /// Decodes GitHub's release object. Only `tag_name` is required; `draft` and `prerelease`
    /// default to `false`, `assets` to empty, and timestamps are read as ISO 8601 strings whatever
    /// the decoder's date strategy.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try container.decodeIfPresent(Int64.self, forKey: .id)
        self.tagName = try container.decode(String.self, forKey: .tagName)
        self.name = try container.decodeIfPresent(String.self, forKey: .name)
        self.body = try container.decodeIfPresent(String.self, forKey: .body)
        self.targetCommitish = try container.decodeIfPresent(String.self, forKey: .targetCommitish)
        self.draft = try container.decodeIfPresent(Bool.self, forKey: .draft) ?? false
        self.prerelease = try container.decodeIfPresent(Bool.self, forKey: .prerelease) ?? false
        self.htmlURL = try container.decodeIfPresent(String.self, forKey: .htmlURL)
        self.tarballURL = try container.decodeIfPresent(String.self, forKey: .tarballURL)
        self.zipballURL = try container.decodeIfPresent(String.self, forKey: .zipballURL)
        self.createdAt = try container.decodeGitHubDateIfPresent(forKey: .createdAt)
        self.publishedAt = try container.decodeGitHubDateIfPresent(forKey: .publishedAt)
        self.assets = try container.decodeIfPresent([GitHubReleaseAsset].self, forKey: .assets) ?? []
        self.nodeID = try container.decodeIfPresent(String.self, forKey: .nodeID)
        self.url = try container.decodeIfPresent(String.self, forKey: .url)
        self.assetsURL = try container.decodeIfPresent(String.self, forKey: .assetsURL)
        self.uploadURL = try container.decodeIfPresent(String.self, forKey: .uploadURL)
        self.author = try container.decodeIfPresent(GitHubAccount.self, forKey: .author)
    }

    /// Encodes with GitHub's snake_case keys and ISO 8601 timestamps, omitting absent fields.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encodeIfPresent(id, forKey: .id)
        try container.encode(tagName, forKey: .tagName)
        try container.encodeIfPresent(name, forKey: .name)
        try container.encodeIfPresent(body, forKey: .body)
        try container.encodeIfPresent(targetCommitish, forKey: .targetCommitish)
        try container.encode(draft, forKey: .draft)
        try container.encode(prerelease, forKey: .prerelease)
        try container.encodeIfPresent(htmlURL, forKey: .htmlURL)
        try container.encodeIfPresent(tarballURL, forKey: .tarballURL)
        try container.encodeIfPresent(zipballURL, forKey: .zipballURL)
        try container.encodeGitHubDateIfPresent(createdAt, forKey: .createdAt)
        try container.encodeGitHubDateIfPresent(publishedAt, forKey: .publishedAt)
        try container.encode(assets, forKey: .assets)
        try container.encodeIfPresent(nodeID, forKey: .nodeID)
        try container.encodeIfPresent(url, forKey: .url)
        try container.encodeIfPresent(assetsURL, forKey: .assetsURL)
        try container.encodeIfPresent(uploadURL, forKey: .uploadURL)
        try container.encodeIfPresent(author, forKey: .author)
    }
}
