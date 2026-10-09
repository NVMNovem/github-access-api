//
//  GitHubSetupCallbackError.swift
//  github-access-api
//
//  Created by Damian Van de Kauter on 09/10/2026.
//

/// Why a setup redirect could not be read as a ``GitHubSetupCallback``.
public enum GitHubSetupCallbackError: Error, Hashable, Sendable {

    /// The URL has no readable query.
    case unreadableURL

    /// There is no `installation_id`, and the `setup_action` is not `request` — the one action
    /// for which GitHub has no installation to report.
    case missingInstallationID

    /// The `installation_id` is not a positive integer that fits in 64 bits. Carries the raw value.
    case invalidInstallationID(String)

    /// A parameter that must appear at most once appeared more than once. Carries its name.
    ///
    /// Two `installation_id`s or two `state`s are refused rather than resolved by picking one:
    /// GitHub never sends either twice, so a duplicate means the URL was tampered with.
    case duplicateParameter(String)
}
