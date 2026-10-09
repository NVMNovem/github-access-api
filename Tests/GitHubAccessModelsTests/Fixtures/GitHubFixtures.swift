//
//  GitHubFixtures.swift
//  github-access-api
//
//  Created by Damian Van de Kauter on 09/10/2026.
//

import Foundation

/// Payloads written from the examples in GitHub's REST API and webhook documentation, kept as
/// GitHub sends them: snake_case, `null`s, fields this package does not model, and both timestamp
/// forms GitHub uses (`Z` and a `-04:00` offset).
///
/// Kept as Swift strings rather than resource files so the tests need no `Bundle.module`, which is
/// not available on every platform this package targets.
enum GitHubFixtures {

    static let octocatUser = """
    {
      "login": "octocat",
      "id": 1,
      "node_id": "MDQ6VXNlcjE=",
      "avatar_url": "https://github.com/images/error/octocat_happy.gif",
      "gravatar_id": "",
      "url": "https://api.github.com/users/octocat",
      "html_url": "https://github.com/octocat",
      "followers_url": "https://api.github.com/users/octocat/followers",
      "repos_url": "https://api.github.com/users/octocat/repos",
      "type": "User",
      "site_admin": false
    }
    """

    /// `GET /repos/{owner}/{repo}/releases/{release_id}`.
    static let release = """
    {
      "url": "https://api.github.com/repos/octocat/Hello-World/releases/1",
      "html_url": "https://github.com/octocat/Hello-World/releases/v1.0.0",
      "assets_url": "https://api.github.com/repos/octocat/Hello-World/releases/1/assets",
      "upload_url": "https://uploads.github.com/repos/octocat/Hello-World/releases/1/assets{?name,label}",
      "tarball_url": "https://api.github.com/repos/octocat/Hello-World/tarball/v1.0.0",
      "zipball_url": "https://api.github.com/repos/octocat/Hello-World/zipball/v1.0.0",
      "discussion_url": "https://github.com/octocat/Hello-World/discussions/90",
      "id": 1,
      "node_id": "MDc6UmVsZWFzZTE=",
      "tag_name": "v1.0.0",
      "target_commitish": "master",
      "name": "v1.0.0",
      "body": "Description of the release",
      "draft": false,
      "prerelease": false,
      "immutable": false,
      "created_at": "2013-02-27T19:35:32Z",
      "published_at": "2013-02-27T19:35:32Z",
      "author": \(octocatUser),
      "assets": [
        {
          "url": "https://api.github.com/repos/octocat/Hello-World/releases/assets/1",
          "browser_download_url": "https://github.com/octocat/Hello-World/releases/download/v1.0.0/example.zip",
          "id": 1,
          "node_id": "MDEyOlJlbGVhc2VBc3NldDE=",
          "name": "example.zip",
          "label": "short description",
          "state": "uploaded",
          "content_type": "application/zip",
          "size": 1024,
          "digest": "sha256:2151b604e3429bff440b9fbc03eb3617bc2603cda96c95b9bb05277f9ddba255",
          "download_count": 42,
          "created_at": "2013-02-27T19:35:32Z",
          "updated_at": "2013-02-27T19:35:32Z",
          "uploader": \(octocatUser)
        }
      ]
    }
    """

    /// A draft, as `GET /repos/{owner}/{repo}/releases` lists it: no title, no publication date.
    static let draftRelease = """
    {
      "id": 2,
      "tag_name": "v2.0.0-rc.1",
      "name": null,
      "body": null,
      "draft": true,
      "prerelease": true,
      "created_at": "2013-03-01T08:00:00Z",
      "published_at": null,
      "assets": []
    }
    """

    /// The `release` object inside github-access-vapor's own `release.published` webhook fixture.
    /// Decoding it here proves the vapor package can switch to these types without losing data.
    static let vaporWebhookRelease = """
    {
      "id" : 900,
      "tag_name" : "1.4.0",
      "name" : "Release caf\\u00e9 1.4.0",
      "draft" : false,
      "prerelease" : false,
      "html_url" : "https://github.com/octocat/hello-world/releases/tag/1.4.0",
      "published_at" : "2026-08-10T09:15:30Z",
      "assets" : []
    }
    """

    /// `GET /app/installations/{installation_id}`.
    static let installation = """
    {
      "id": 1,
      "account": \(octocatUser),
      "access_tokens_url": "https://api.github.com/app/installations/1/access_tokens",
      "repositories_url": "https://api.github.com/installation/repositories",
      "html_url": "https://github.com/organizations/github/settings/installations/1",
      "app_id": 1,
      "target_id": 1,
      "target_type": "Organization",
      "permissions": {
        "checks": "write",
        "metadata": "read",
        "contents": "read"
      },
      "events": [
        "push",
        "pull_request"
      ],
      "single_file_name": "config.yaml",
      "has_multiple_single_files": true,
      "single_file_paths": [
        "config.yml",
        ".github/issue_TEMPLATE.md"
      ],
      "repository_selection": "selected",
      "created_at": "2017-07-08T16:18:44-04:00",
      "updated_at": "2017-07-08T16:18:44-04:00",
      "app_slug": "github-actions",
      "suspended_at": null,
      "suspended_by": null
    }
    """

    /// The `installation` object of an enterprise installation, whose account has a slug and no
    /// login, suspended by a site administrator.
    static let suspendedEnterpriseInstallation = """
    {
      "id": 7,
      "account": {
        "description": "A great enterprise",
        "html_url": "https://github.com/enterprises/octo-business",
        "website_url": "https://example.com",
        "id": 42,
        "node_id": "MDEwOlJlcG9zaXRvcnkxMjk2MjY5",
        "name": "Octo Business",
        "slug": "octo-business",
        "created_at": "2019-01-26T19:01:12Z",
        "updated_at": "2019-01-26T19:14:43Z",
        "avatar_url": "https://github.com/images/error/octocat_happy.gif"
      },
      "repository_selection": "all",
      "app_id": 1,
      "app_slug": "funico-server-manager",
      "target_type": "Enterprise",
      "permissions": { "contents": "read", "metadata": "read" },
      "events": ["release"],
      "created_at": "2026-10-01T10:00:00Z",
      "updated_at": "2026-10-02T10:00:00Z",
      "suspended_at": "2026-10-03T12:30:00.250Z",
      "suspended_by": \(octocatUser)
    }
    """

    /// One entry of an `installation_repositories` webhook's `repositories_added`.
    static let repositoryAdded = """
    {
      "id": 1296269,
      "node_id": "MDEwOlJlcG9zaXRvcnkxMjk2MjY5",
      "name": "Hello-World",
      "full_name": "octocat/Hello-World",
      "private": false
    }
    """

    /// A full repository from `GET /installation/repositories`, trimmed of the dozens of `*_url`
    /// fields this package ignores.
    static let fullRepository = """
    {
      "id": 1296269,
      "node_id": "MDEwOlJlcG9zaXRvcnkxMjk2MjY5",
      "name": "Hello-World",
      "full_name": "octocat/Hello-World",
      "owner": \(octocatUser),
      "private": true,
      "html_url": "https://github.com/octocat/Hello-World",
      "description": "This your first repo!",
      "fork": false,
      "url": "https://api.github.com/repos/octocat/Hello-World",
      "clone_url": "https://github.com/octocat/Hello-World.git",
      "default_branch": "master",
      "visibility": "private",
      "pushed_at": "2011-01-26T19:06:43Z"
    }
    """

    /// The example manifest from GitHub's "Registering a GitHub App from a manifest".
    static let manifest = """
    {
      "name": "Octoapp",
      "url": "https://www.example.com",
      "hook_attributes": {
        "url": "https://example.com/github/events"
      },
      "redirect_url": "https://example.com/redirect",
      "callback_urls": [
        "https://example.com/callback"
      ],
      "public": true,
      "default_permissions": {
        "issues": "write",
        "checks": "write"
      },
      "default_events": [
        "issues",
        "issue_comment",
        "check_suite",
        "check_run"
      ]
    }
    """

    /// `POST /app-manifests/{code}/conversions`, as documented. The key is GitHub's truncated
    /// example, not a real one.
    static let manifestConversion = """
    {
      "id": 1,
      "slug": "octoapp",
      "node_id": "MDxOkludGVncmF0aW9uMQ==",
      "owner": {
        "login": "github",
        "id": 1,
        "node_id": "MDEyOk9yZ2FuaXphdGlvbjE=",
        "url": "https://api.github.com/orgs/github",
        "avatar_url": "https://github.com/images/error/octocat_happy.gif",
        "type": "Organization",
        "site_admin": false
      },
      "name": "Octocat App",
      "description": "",
      "external_url": "https://example.com",
      "html_url": "https://github.com/apps/octoapp",
      "created_at": "2017-07-08T16:18:44-04:00",
      "updated_at": "2017-07-08T16:18:44-04:00",
      "permissions": {
        "metadata": "read",
        "contents": "read",
        "issues": "write",
        "single_file": "write"
      },
      "events": [
        "push",
        "pull_request"
      ],
      "client_id": "Iv1.8a61f9b3a7aba766",
      "client_secret": "1726be1638095a19edd134c77bde3aa2ece1e5d8",
      "webhook_secret": "e340154128314309424b7c8e90325147d99fdafa",
      "pem": "-----BEGIN RSA PRIVATE KEY-----\\nMIIEowIBAAKCAQEAuEPzOUE+kiEH1WLiMeBytTEF856j0hOVcSUSUkZxKvqczkWM\\n9vo1gDyC7ZXhdH9fKh32aapba3RSsp4ke+giSmYTk2mGR538ShSDxh0OgpJmjiKP\\n-----END RSA PRIVATE KEY-----\\n"
    }
    """
}

extension String {

    var utf8Data: Data { Data(utf8) }
}
