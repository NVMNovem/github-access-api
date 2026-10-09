//
//  GitHubReleaseAsset.swift
//  github-access-api
//
//  Created by Damian Van de Kauter on 09/10/2026.
//

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// A file attached to a release.
///
/// Field names and JSON keys follow GitHub's REST API. Like ``GitHubRelease``, this replaces
/// github-access-vapor's type of the same name: its properties and initializer parameters keep
/// their names, types and order, and the extra fields are appended with defaults.
///
/// There are two ways to download an asset, and they behave differently for a private repository:
///
/// - ``browserDownloadURL`` is the github.com link a person clicks. It does not accept an
///   installation token, so it only works for public repositories.
/// - ``url`` is the REST endpoint. Requested with `Accept: application/octet-stream` and an
///   installation token, it answers with a redirect to a short-lived download URL — follow it, and
///   do not forward the `Authorization` header to the redirect's host.
public struct GitHubReleaseAsset: Codable, Sendable, Hashable {

    /// The asset's numeric ID.
    public var id: Int64?

    /// The file name, such as `server-linux-x86_64.tar.gz`. The one field GitHub always sends.
    public var name: String

    /// A short description shown instead of the file name on the release page.
    public var label: String?

    /// The MIME type the uploader declared. Not verified by GitHub.
    public var contentType: String?

    /// The size in bytes.
    public var size: Int?

    /// The github.com download link. Works without authentication for public repositories only.
    public var browserDownloadURL: String?

    /// The asset's REST endpoint, which serves the file to an authenticated client.
    public var url: String?

    /// The GraphQL node ID.
    public var nodeID: String?

    /// `uploaded` once the file is complete, `open` while an upload is in progress. Only download
    /// an `uploaded` asset.
    public var state: String?

    /// The file's digest as `<algorithm>:<hex>`, such as `sha256:…`, when GitHub has computed one.
    /// Compare it against the downloaded bytes before trusting them.
    public var digest: String?

    /// How many times the asset has been downloaded.
    public var downloadCount: Int?

    /// When the asset was uploaded.
    public var createdAt: Date?

    /// When the asset last changed.
    public var updatedAt: Date?

    /// Who uploaded the asset.
    public var uploader: GitHubAccount?

    /// Creates an asset.
    ///
    /// The parameters up to `url` match github-access-vapor's `GitHubReleaseAsset` initializer in
    /// name and order, so existing call sites keep compiling.
    ///
    /// - Parameters:
    ///   - id: The asset's numeric ID.
    ///   - name: The file name.
    ///   - label: A short description.
    ///   - contentType: The declared MIME type.
    ///   - size: The size in bytes.
    ///   - browserDownloadURL: The github.com download link.
    ///   - url: The asset's REST endpoint.
    ///   - nodeID: The GraphQL node ID.
    ///   - state: `uploaded` or `open`.
    ///   - digest: The file's digest, such as `sha256:…`.
    ///   - downloadCount: How many times the asset has been downloaded.
    ///   - createdAt: When the asset was uploaded.
    ///   - updatedAt: When the asset last changed.
    ///   - uploader: Who uploaded the asset.
    public init(
        id: Int64? = nil,
        name: String,
        label: String? = nil,
        contentType: String? = nil,
        size: Int? = nil,
        browserDownloadURL: String? = nil,
        url: String? = nil,
        nodeID: String? = nil,
        state: String? = nil,
        digest: String? = nil,
        downloadCount: Int? = nil,
        createdAt: Date? = nil,
        updatedAt: Date? = nil,
        uploader: GitHubAccount? = nil
    ) {
        self.id = id
        self.name = name
        self.label = label
        self.contentType = contentType
        self.size = size
        self.browserDownloadURL = browserDownloadURL
        self.url = url
        self.nodeID = nodeID
        self.state = state
        self.digest = digest
        self.downloadCount = downloadCount
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.uploader = uploader
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case label
        case contentType = "content_type"
        case size
        case browserDownloadURL = "browser_download_url"
        case url
        case nodeID = "node_id"
        case state
        case digest
        case downloadCount = "download_count"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case uploader
    }

    /// Decodes GitHub's asset object. Only `name` is required.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try container.decodeIfPresent(Int64.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        self.label = try container.decodeIfPresent(String.self, forKey: .label)
        self.contentType = try container.decodeIfPresent(String.self, forKey: .contentType)
        self.size = try container.decodeIfPresent(Int.self, forKey: .size)
        self.browserDownloadURL = try container.decodeIfPresent(String.self, forKey: .browserDownloadURL)
        self.url = try container.decodeIfPresent(String.self, forKey: .url)
        self.nodeID = try container.decodeIfPresent(String.self, forKey: .nodeID)
        self.state = try container.decodeIfPresent(String.self, forKey: .state)
        self.digest = try container.decodeIfPresent(String.self, forKey: .digest)
        self.downloadCount = try container.decodeIfPresent(Int.self, forKey: .downloadCount)
        self.createdAt = try container.decodeGitHubDateIfPresent(forKey: .createdAt)
        self.updatedAt = try container.decodeGitHubDateIfPresent(forKey: .updatedAt)
        self.uploader = try container.decodeIfPresent(GitHubAccount.self, forKey: .uploader)
    }

    /// Encodes with GitHub's snake_case keys and ISO 8601 timestamps, omitting absent fields.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encodeIfPresent(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(label, forKey: .label)
        try container.encodeIfPresent(contentType, forKey: .contentType)
        try container.encodeIfPresent(size, forKey: .size)
        try container.encodeIfPresent(browserDownloadURL, forKey: .browserDownloadURL)
        try container.encodeIfPresent(url, forKey: .url)
        try container.encodeIfPresent(nodeID, forKey: .nodeID)
        try container.encodeIfPresent(state, forKey: .state)
        try container.encodeIfPresent(digest, forKey: .digest)
        try container.encodeIfPresent(downloadCount, forKey: .downloadCount)
        try container.encodeGitHubDateIfPresent(createdAt, forKey: .createdAt)
        try container.encodeGitHubDateIfPresent(updatedAt, forKey: .updatedAt)
        try container.encodeIfPresent(uploader, forKey: .uploader)
    }
}
