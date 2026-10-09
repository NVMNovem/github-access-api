//
//  GitHubReleaseTests.swift
//  github-access-api
//
//  Created by Damian Van de Kauter on 09/10/2026.
//

import Foundation
import Testing
import GitHubAccessModels

@Suite("GitHubRelease and GitHubReleaseAsset")
struct GitHubReleaseTests {

    @Test("Decodes GitHub's documented release, every modelled field")
    func decodesDocumentedRelease() throws {
        let release = try decode(GitHubRelease.self, from: GitHubFixtures.release)

        #expect(release.id == 1)
        #expect(release.nodeID == "MDc6UmVsZWFzZTE=")
        #expect(release.tagName == "v1.0.0")
        #expect(release.name == "v1.0.0")
        #expect(release.body == "Description of the release")
        #expect(release.targetCommitish == "master")
        #expect(release.draft == false)
        #expect(release.prerelease == false)
        #expect(release.url == "https://api.github.com/repos/octocat/Hello-World/releases/1")
        #expect(release.htmlURL == "https://github.com/octocat/Hello-World/releases/v1.0.0")
        #expect(release.assetsURL == "https://api.github.com/repos/octocat/Hello-World/releases/1/assets")
        #expect(release.uploadURL == "https://uploads.github.com/repos/octocat/Hello-World/releases/1/assets{?name,label}")
        #expect(release.tarballURL == "https://api.github.com/repos/octocat/Hello-World/tarball/v1.0.0")
        #expect(release.zipballURL == "https://api.github.com/repos/octocat/Hello-World/zipball/v1.0.0")
        #expect(release.createdAt == Date(timeIntervalSince1970: 1_361_993_732))
        #expect(release.publishedAt == Date(timeIntervalSince1970: 1_361_993_732))
        #expect(release.author?.login == "octocat")
        #expect(release.author?.type == .user)

        let asset = try #require(release.assets.first)
        #expect(release.assets.count == 1)
        #expect(asset.id == 1)
        #expect(asset.nodeID == "MDEyOlJlbGVhc2VBc3NldDE=")
        #expect(asset.name == "example.zip")
        #expect(asset.label == "short description")
        #expect(asset.state == "uploaded")
        #expect(asset.contentType == "application/zip")
        #expect(asset.size == 1024)
        #expect(asset.digest == "sha256:2151b604e3429bff440b9fbc03eb3617bc2603cda96c95b9bb05277f9ddba255")
        #expect(asset.downloadCount == 42)
        #expect(asset.url == "https://api.github.com/repos/octocat/Hello-World/releases/assets/1")
        #expect(asset.browserDownloadURL == "https://github.com/octocat/Hello-World/releases/download/v1.0.0/example.zip")
        #expect(asset.createdAt == Date(timeIntervalSince1970: 1_361_993_732))
        #expect(asset.updatedAt == Date(timeIntervalSince1970: 1_361_993_732))
        #expect(asset.uploader?.id == 1)
    }

    @Test("Round trips without losing a modelled field")
    func roundTrips() throws {
        let release = try decode(GitHubRelease.self, from: GitHubFixtures.release)

        let actual23 = try roundTrip(release)
        #expect(actual23 == release)
    }

    @Test("Encodes GitHub's snake_case keys and ISO 8601 timestamps")
    func encodesGitHubKeys() throws {
        let release = try decode(GitHubRelease.self, from: GitHubFixtures.release)
        let object = try jsonObject(release)

        #expect(object["tag_name"] as? String == "v1.0.0")
        #expect(object["target_commitish"] as? String == "master")
        #expect(object["html_url"] as? String == "https://github.com/octocat/Hello-World/releases/v1.0.0")
        #expect(object["published_at"] as? String == "2013-02-27T19:35:32Z")
        #expect(object["node_id"] as? String == "MDc6UmVsZWFzZTE=")
        #expect(object["tagName"] == nil)

        let asset = try #require((object["assets"] as? [[String: Any]])?.first)
        #expect(asset["browser_download_url"] as? String == "https://github.com/octocat/Hello-World/releases/download/v1.0.0/example.zip")
        #expect(asset["content_type"] as? String == "application/zip")
        #expect(asset["download_count"] as? Int == 42)
    }

    @Test("A draft decodes with a null name and no publication date")
    func decodesDraft() throws {
        let release = try decode(GitHubRelease.self, from: GitHubFixtures.draftRelease)

        #expect(release.draft)
        #expect(release.prerelease)
        #expect(release.name == nil)
        #expect(release.body == nil)
        #expect(release.publishedAt == nil)
        #expect(release.assets.isEmpty)
        let actual24 = try roundTrip(release)
        #expect(actual24 == release)
    }

    @Test("Decodes github-access-vapor's webhook release with nothing lost")
    func decodesVaporWebhookRelease() throws {
        let release = try decode(GitHubRelease.self, from: GitHubFixtures.vaporWebhookRelease)

        #expect(release.id == 900)
        #expect(release.tagName == "1.4.0")
        #expect(release.name == "Release café 1.4.0")
        #expect(release.htmlURL == "https://github.com/octocat/hello-world/releases/tag/1.4.0")
        #expect(release.publishedAt == Date(timeIntervalSince1970: 1_786_353_330))
    }

    @Test("Decodes with a decoder whose date strategy is .iso8601, as github-access-vapor's is")
    func decodesWithISO8601Strategy() throws {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let release = try decoder.decode(GitHubRelease.self, from: GitHubFixtures.release.utf8Data)

        #expect(release.publishedAt == Date(timeIntervalSince1970: 1_361_993_732))
    }

    @Test("Only tag_name is required; missing flags and assets take their defaults")
    func minimalRelease() throws {
        let release = try decode(GitHubRelease.self, from: #"{"tag_name":"v1"}"#)

        #expect(release == GitHubRelease(tagName: "v1"))
        #expect(throws: DecodingError.self) {
            try decode(GitHubRelease.self, from: #"{"name":"no tag"}"#)
        }
    }

    @Test("A timestamp that is not ISO 8601 is a decoding error, not a silent nil")
    func rejectsMalformedTimestamp() {
        #expect(throws: DecodingError.self) {
            try decode(GitHubRelease.self, from: #"{"tag_name":"v1","published_at":"yesterday"}"#)
        }
    }

    @Test("Initializer parameters match github-access-vapor's, in order")
    func vaporCompatibleInitializers() {
        // These are the exact call shapes github-access-vapor's types accept.
        let asset = GitHubReleaseAsset(
            id: 3, name: "server.tar.gz", label: nil, contentType: "application/gzip",
            size: 10, browserDownloadURL: "https://example.com/a", url: "https://example.com/b"
        )
        let release = GitHubRelease(
            id: 1, tagName: "v1", name: "One", body: "Notes", targetCommitish: "main",
            draft: false, prerelease: true, htmlURL: nil, tarballURL: nil, zipballURL: nil,
            createdAt: nil, publishedAt: Date(timeIntervalSince1970: 0), assets: [asset]
        )

        #expect(release.assets.first?.contentType == "application/gzip")
        #expect(release.prerelease)
    }
}
