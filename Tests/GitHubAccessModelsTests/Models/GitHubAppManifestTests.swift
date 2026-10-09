//
//  GitHubAppManifestTests.swift
//  github-access-api
//
//  Created by Damian Van de Kauter on 09/10/2026.
//

import Foundation
import Testing
import GitHubAccessModels

@Suite("GitHubAppManifest and GitHubAppManifestConversion")
struct GitHubAppManifestTests {

    private let serverManager = GitHubAppManifest.serverManager(
        name: "Funico Server Manager",
        url: URL(string: "https://manager.example.com")!,
        webhookURL: URL(string: "https://manager.example.com/github/webhook")!,
        redirectURL: URL(string: "https://manager.example.com/github/manifest/callback")!,
        setupURL: URL(string: "https://manager.example.com/github/setup")!
    )

    @Test("Decodes GitHub's documented example manifest and round trips it")
    func decodesDocumentedManifest() throws {
        let manifest = try decode(GitHubAppManifest.self, from: GitHubFixtures.manifest)

        #expect(manifest.name == "Octoapp")
        #expect(manifest.url.absoluteString == "https://www.example.com")
        #expect(manifest.hookAttributes?.url.absoluteString == "https://example.com/github/events")
        #expect(manifest.hookAttributes?.active == nil)
        #expect(manifest.redirectURL?.absoluteString == "https://example.com/redirect")
        #expect(manifest.callbackURLs.map(\.absoluteString) == ["https://example.com/callback"])
        #expect(manifest.isPublic)
        #expect(manifest.defaultPermissions == ["issues": .write, "checks": .write])
        #expect(manifest.defaultEvents == ["issues", "issue_comment", "check_suite", "check_run"])
        let actual19 = try roundTrip(manifest)
        #expect(actual19 == manifest)
    }

    @Test("Encodes back to exactly GitHub's documented JSON")
    func encodesDocumentedManifest() throws {
        let manifest = try decode(GitHubAppManifest.self, from: GitHubFixtures.manifest)

        let encoded = try JSONSerialization.jsonObject(with: Data(try manifest.jsonString().utf8)) as? NSDictionary
        let documented = try JSONSerialization.jsonObject(with: GitHubFixtures.manifest.utf8Data) as? NSDictionary

        #expect(encoded == documented)
    }

    @Test("The Server Manager preset asks for least privilege")
    func serverManagerPreset() throws {
        let object = try jsonObject(serverManager)

        #expect(object["default_permissions"] as? [String: String] == ["contents": "read", "metadata": "read"])
        #expect(object["default_events"] as? [String] == ["release"])
        #expect(object["public"] as? Bool == false)
        #expect(object["setup_on_update"] as? Bool == true)
        #expect(object["request_oauth_on_install"] as? Bool == false)
        #expect(object["setup_url"] as? String == "https://manager.example.com/github/setup")
        #expect(object["redirect_url"] as? String == "https://manager.example.com/github/manifest/callback")
        #expect(object["callback_urls"] == nil)

        let hook = try #require(object["hook_attributes"] as? [String: Any])
        #expect(hook["url"] as? String == "https://manager.example.com/github/webhook")
        #expect(hook["active"] as? Bool == true)

        // Nothing may write.
        #expect(!serverManager.defaultPermissions.values.contains { $0 != .read })
    }

    @Test("Without a setup URL the preset leaves setup_on_update out")
    func presetWithoutSetupURL() throws {
        let manifest = GitHubAppManifest.serverManager(
            name: "M",
            url: URL(string: "https://m.test")!,
            webhookURL: URL(string: "https://m.test/hook")!,
            redirectURL: URL(string: "https://m.test/cb")!
        )

        let actual20 = try jsonObject(manifest)["setup_on_update"]
        #expect(actual20 == nil)
        let actual21 = try jsonObject(manifest)["setup_url"]
        #expect(actual21 == nil)
    }

    @Test("jsonString is compact, key-sorted and leaves slashes unescaped")
    func jsonStringFormat() throws {
        let json = try serverManager.jsonString()

        #expect(json.hasPrefix(#"{"default_events":["release"],"default_permissions":{"contents":"read","metadata":"read"},"#))
        #expect(json.contains(#""url":"https://manager.example.com""#))
        #expect(!json.contains(#"\/"#))
        #expect(!json.contains("\n"))
    }

    @Test("Registration URL for a personal account")
    func userRegistration() throws {
        let registration = try serverManager.registration(state: "abc123")

        #expect(registration.url.absoluteString == "https://github.com/settings/apps/new?state=abc123")
        #expect(registration.state == "abc123")
        #expect(registration.formFieldName == "manifest")
        let expectedJSON = try serverManager.jsonString()
        #expect(registration.manifestJSON == expectedJSON)
    }

    @Test("Registration URL for an organization, with the state encoded")
    func organizationRegistration() throws {
        let registration = try serverManager.registration(for: .organization("Funico-NV"), state: "a+b/c")

        #expect(registration.url.absoluteString == "https://github.com/organizations/Funico-NV/settings/apps/new?state=a%2Bb%2Fc")
    }

    @Test("The form body decodes back to the manifest")
    func formBody() throws {
        let registration = try serverManager.registration(state: "s")
        let body = registration.formURLEncodedBody

        #expect(body.hasPrefix("manifest=%7B%22default_events%22"))
        #expect(!body.contains("+"))

        let components = try #require(URLComponents(string: "https://x.test/?\(body)"))
        let field = try #require(components.queryItems?.first { $0.name == "manifest" }?.value)
        let decoded = try JSONDecoder().decode(GitHubAppManifest.self, from: Data(field.utf8))

        #expect(decoded == serverManager)
    }

    @Test(
        "Refuses an organization login that is not one",
        arguments: ["", "-funico", "funico/evil", "funi co", "funico.nv", "funico?x", String(repeating: "a", count: 40)]
    )
    func rejectsBadOrganization(login: String) {
        #expect(throws: GitHubLinkError.invalidOrganization(login)) {
            try serverManager.registration(for: .organization(login), state: "s")
        }
    }

    @Test("Refuses an empty state")
    func rejectsEmptyState() {
        #expect(throws: GitHubLinkError.missingState) {
            try serverManager.registration(state: "")
        }
    }

    @Test("Decodes GitHub's documented conversion response, secrets included")
    func decodesConversion() throws {
        let conversion = try decode(GitHubAppManifestConversion.self, from: GitHubFixtures.manifestConversion)

        #expect(conversion.id == 1)
        #expect(conversion.slug == "octoapp")
        #expect(conversion.nodeID == "MDxOkludGVncmF0aW9uMQ==")
        #expect(conversion.name == "Octocat App")
        #expect(conversion.description == "")
        #expect(conversion.owner?.login == "github")
        #expect(conversion.owner?.type == .organization)
        #expect(conversion.externalURL == "https://example.com")
        #expect(conversion.htmlURL == "https://github.com/apps/octoapp")
        #expect(conversion.createdAt == Date(timeIntervalSince1970: 1_499_545_124))
        #expect(conversion.permissions["single_file"] == .write)
        #expect(conversion.events == ["push", "pull_request"])
        #expect(conversion.clientID == "Iv1.8a61f9b3a7aba766")
        #expect(conversion.clientSecret == "1726be1638095a19edd134c77bde3aa2ece1e5d8")
        #expect(conversion.webhookSecret == "e340154128314309424b7c8e90325147d99fdafa")
        #expect(conversion.pem.hasPrefix("-----BEGIN RSA PRIVATE KEY-----\n"))
        #expect(conversion.pem.hasSuffix("-----END RSA PRIVATE KEY-----\n"))

        // A secret store must receive every secret back.
        let actual22 = try roundTrip(conversion)
        #expect(actual22 == conversion)
        let object = try jsonObject(conversion)
        #expect(object["client_secret"] as? String == conversion.clientSecret)
        #expect(object["webhook_secret"] as? String == conversion.webhookSecret)
        #expect(object["pem"] as? String == conversion.pem)
    }

    @Test("print, interpolation and dump never show the secrets")
    func redactsSecrets() throws {
        let conversion = try decode(GitHubAppManifestConversion.self, from: GitHubFixtures.manifestConversion)

        var dumped = ""
        dump(conversion, to: &dumped)

        for rendered in [String(describing: conversion), "\(conversion)", String(reflecting: conversion), dumped] {
            #expect(!rendered.contains(conversion.clientSecret))
            let secret = try #require(conversion.webhookSecret)
            #expect(!rendered.contains(secret))
            #expect(!rendered.contains("PRIVATE KEY"))
            #expect(!rendered.contains("MIIEowIBAAKCAQEA"))
            #expect(rendered.contains("octoapp"))
        }
    }

    @Test("A conversion without a key or client secret is not a usable App")
    func requiresSecrets() {
        #expect(throws: DecodingError.self) {
            try decode(GitHubAppManifestConversion.self, from: #"{"id":1,"slug":"x","client_id":"c","client_secret":"s"}"#)
        }
        #expect(throws: DecodingError.self) {
            try decode(GitHubAppManifestConversion.self, from: #"{"id":1,"slug":"x","client_id":"c","pem":"p"}"#)
        }
    }
}
