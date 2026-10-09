//
//  GitHubInstallLinkTests.swift
//  github-access-api
//
//  Created by Damian Van de Kauter on 09/10/2026.
//

import Foundation
import Testing
import GitHubAccessModels

@Suite("GitHubInstallLink")
struct GitHubInstallLinkTests {

    @Test("Builds GitHub's install URL")
    func buildsURL() throws {
        let link = try GitHubInstallLink(appSlug: "funico-server-manager", state: "abc123")

        #expect(link.url.absoluteString == "https://github.com/apps/funico-server-manager/installations/new?state=abc123")
        #expect(link.description == link.url.absoluteString)
        #expect(link.appSlug == "funico-server-manager")
        #expect(link.state == "abc123")
    }

    @Test("Leaves the query off without a state, or with an empty one")
    func withoutState() throws {
        let actual14 = try GitHubInstallLink(appSlug: "octoapp").url.absoluteString
        #expect(actual14 == "https://github.com/apps/octoapp/installations/new")
        let actual15 = try GitHubInstallLink(appSlug: "octoapp", state: "").url.query
        #expect(actual15 == nil)
        let actual16 = try GitHubInstallLink(appSlug: "octoapp", state: "").state
        #expect(actual16 == nil)
    }

    @Test("Percent-encodes every reserved character in the state, including +")
    func encodesState() throws {
        let state = "a+b/c=d&e f?g#h%i~j.k_l-m"
        let link = try GitHubInstallLink(appSlug: "octoapp", state: state)

        #expect(link.url.absoluteString
            == "https://github.com/apps/octoapp/installations/new?state=a%2Bb%2Fc%3Dd%26e%20f%3Fg%23h%25i~j.k_l-m")
        #expect(link.url.fragment == nil)
    }

    @Test("Encodes non-ASCII state as UTF-8")
    func encodesUnicode() throws {
        let link = try GitHubInstallLink(appSlug: "octoapp", state: "café✓")

        #expect(link.url.query == "state=caf%C3%A9%E2%9C%93")
    }

    @Test("The state survives the trip to GitHub and back through GitHubSetupCallback")
    func stateRoundTrips() throws {
        let state = "Zm9v+YmFy/YmF6=="
        let link = try GitHubInstallLink(appSlug: "octoapp", state: state)

        // GitHub echoes the state verbatim onto the setup URL.
        let query = try #require(link.url.query)
        let redirect = try #require(URL(string: "https://manager.example.com/github/setup?installation_id=9&setup_action=install&\(query)"))

        let actual17 = try GitHubSetupCallback(url: redirect).state
        #expect(actual17 == state)
    }

    @Test(
        "Refuses a slug that could move the link elsewhere on github.com",
        arguments: ["", "octo/app", "../settings", "octo.app", "octo?app", "octo#app", "octo app", "octo%2Fapp", "ócto", String(repeating: "a", count: 101)]
    )
    func rejectsUnsafeSlug(slug: String) {
        #expect(throws: GitHubLinkError.invalidAppSlug(slug)) {
            try GitHubInstallLink(appSlug: slug, state: "s")
        }
    }

    @Test("Accepts letters, digits, - and _")
    func acceptsSafeSlug() throws {
        let actual18 = try GitHubInstallLink(appSlug: "Funico_Server-Manager2").url.path
        #expect(actual18 == "/apps/Funico_Server-Manager2/installations/new")
    }
}
