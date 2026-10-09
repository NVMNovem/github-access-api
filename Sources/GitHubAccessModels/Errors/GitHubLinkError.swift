//
//  GitHubLinkError.swift
//  github-access-api
//
//  Created by Damian Van de Kauter on 09/10/2026.
//

/// Why a github.com link could not be built.
public enum GitHubLinkError: Error, Hashable, Sendable {

    /// The App slug is empty, too long, or has a character other than a letter, digit, `-` or `_`.
    /// Carries the rejected slug.
    ///
    /// The slug is placed in the URL *path*, where `/`, `.` or `?` could point the link at a
    /// different page on github.com, so an invalid slug is refused rather than encoded.
    case invalidAppSlug(String)

    /// The organization login is not a valid GitHub login: up to 39 letters, digits and hyphens,
    /// not starting with a hyphen. Carries the rejected login.
    case invalidOrganization(String)

    /// The `state` is empty. The manifest flow requires one, because it is the only thing tying
    /// GitHub's redirect back to the request that started it.
    case missingState
}
