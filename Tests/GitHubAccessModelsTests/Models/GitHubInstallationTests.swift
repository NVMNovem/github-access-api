//
//  GitHubInstallationTests.swift
//  github-access-api
//
//  Created by Damian Van de Kauter on 09/10/2026.
//

import Foundation
import Testing
import GitHubAccessModels

@Suite("GitHubInstallation, GitHubRepositoryRef and GitHubAccount")
struct GitHubInstallationTests {

    @Test("Decodes GitHub's documented installation")
    func decodesDocumentedInstallation() throws {
        let installation = try decode(GitHubInstallation.self, from: GitHubFixtures.installation)

        #expect(installation.id == 1)
        #expect(installation.account?.login == "octocat")
        #expect(installation.account?.type == .user)
        #expect(installation.account?.handle == "octocat")
        #expect(installation.repositorySelection == .selected)
        #expect(installation.appID == 1)
        #expect(installation.appSlug == "github-actions")
        #expect(installation.targetID == 1)
        #expect(installation.targetType == .organization)
        #expect(installation.permissions == ["checks": .write, "metadata": .read, "contents": .read])
        #expect(installation.events == ["push", "pull_request"])
        #expect(installation.accessTokensURL == "https://api.github.com/app/installations/1/access_tokens")
        #expect(installation.repositoriesURL == "https://api.github.com/installation/repositories")
        #expect(installation.htmlURL == "https://github.com/organizations/github/settings/installations/1")
        // "2017-07-08T16:18:44-04:00": an offset, not Z.
        #expect(installation.createdAt == Date(timeIntervalSince1970: 1_499_545_124))
        #expect(installation.suspendedAt == nil)
        #expect(installation.suspendedBy == nil)
        #expect(installation.isSuspended == false)
    }

    @Test("Round trips, and encodes snake_case keys")
    func roundTrips() throws {
        let installation = try decode(GitHubInstallation.self, from: GitHubFixtures.installation)

        let actual1 = try roundTrip(installation)
        #expect(actual1 == installation)

        let object = try jsonObject(installation)
        #expect(object["repository_selection"] as? String == "selected")
        #expect(object["app_slug"] as? String == "github-actions")
        #expect(object["access_tokens_url"] as? String == "https://api.github.com/app/installations/1/access_tokens")
        #expect((object["permissions"] as? [String: String])?["contents"] == "read")
        #expect(object["created_at"] as? String == "2017-07-08T20:18:44Z")
    }

    @Test("A suspended enterprise installation: slug instead of login, fractional timestamp")
    func decodesSuspendedEnterprise() throws {
        let installation = try decode(GitHubInstallation.self, from: GitHubFixtures.suspendedEnterpriseInstallation)

        #expect(installation.isSuspended)
        #expect(installation.suspendedAt == Date(timeIntervalSince1970: 1_791_030_600.25))
        #expect(installation.suspendedBy?.login == "octocat")
        #expect(installation.account?.login == nil)
        #expect(installation.account?.slug == "octo-business")
        #expect(installation.account?.name == "Octo Business")
        #expect(installation.account?.handle == "octo-business")
        #expect(installation.repositorySelection == .all)
        #expect(installation.targetType == .enterprise)
        let actual2 = try roundTrip(installation)
        #expect(actual2 == installation)
    }

    @Test("Unknown open-type values survive a round trip")
    func unknownValuesSurvive() throws {
        let json = #"{"id":5,"repository_selection":"some-future-mode","target_type":"Galaxy","permissions":{"contents":"superuser"}}"#
        let installation = try decode(GitHubInstallation.self, from: json)

        #expect(installation.repositorySelection?.rawValue == "some-future-mode")
        #expect(installation.targetType?.rawValue == "Galaxy")
        #expect(installation.permissions["contents"]?.rawValue == "superuser")
        let actual3 = try roundTrip(installation)
        #expect(actual3 == installation)
    }

    @Test("A repository reference from an installation_repositories webhook")
    func decodesRepositoryAdded() throws {
        let repository = try decode(GitHubRepositoryRef.self, from: GitHubFixtures.repositoryAdded)

        #expect(repository.id == 1_296_269)
        #expect(repository.nodeID == "MDEwOlJlcG9zaXRvcnkxMjk2MjY5")
        #expect(repository.name == "Hello-World")
        #expect(repository.fullName == "octocat/Hello-World")
        #expect(repository.owner == "octocat")
        #expect(repository.isPrivate == false)
        let actual4 = try roundTrip(repository)
        #expect(actual4 == repository)

        let object = try jsonObject(repository)
        #expect(object["full_name"] as? String == "octocat/Hello-World")
        #expect(object["private"] as? Bool == false)
    }

    @Test("A full repository from GET /installation/repositories keeps the deploy fields")
    func decodesFullRepository() throws {
        let repository = try decode(GitHubRepositoryRef.self, from: GitHubFixtures.fullRepository)

        #expect(repository.isPrivate)
        #expect(repository.cloneURL == "https://github.com/octocat/Hello-World.git")
        #expect(repository.htmlURL == "https://github.com/octocat/Hello-World")
        #expect(repository.defaultBranch == "master")
        let actual5 = try roundTrip(repository)
        #expect(actual5 == repository)
    }

    @Test("A reference built from owner/name derives its name")
    func buildsFromFullName() {
        let repository = GitHubRepositoryRef(fullName: "octocat/Hello-World")

        #expect(repository.name == "Hello-World")
        #expect(repository.owner == "octocat")
        #expect(repository.id == nil)
    }
}
