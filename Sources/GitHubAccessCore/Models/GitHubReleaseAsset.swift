//
//  GitHubReleaseAsset.swift
//  github-access-api
//

import Foundation

/// A binary attached to a ``GitHubRelease``.
///
/// Nothing in this package downloads assets yet. They are modelled so that a caller
/// which prefers a prebuilt binary over building from source has something to read.
public struct GitHubReleaseAsset: Sendable, Codable, Hashable, Identifiable {

    /// GitHub's numeric asset identifier.
    public let id: Int64

    /// The file name of the asset, for example `funico-agent-macos-arm64.tar.gz`.
    public let name: String

    /// The asset size in bytes.
    public let size: Int

    /// The MIME type GitHub recorded at upload time, for example `application/gzip`.
    public let contentType: String

    /// The URL to download the asset from, GitHub's `browser_download_url`.
    ///
    /// - Note: For a private repository this URL still requires an `Authorization` header.
    public let downloadURL: URL

    public init(
        id: Int64,
        name: String,
        size: Int,
        contentType: String,
        downloadURL: URL
    ) {
        self.id = id
        self.name = name
        self.size = size
        self.contentType = contentType
        self.downloadURL = downloadURL
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case size
        case contentType = "content_type"
        case downloadURL = "browser_download_url"
    }
}
