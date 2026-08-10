//
//  GitHubClientError.swift
//  github-access-api
//

import Foundation

/// Everything ``GitHubClient`` can fail with.
public enum GitHubClientError: Error, Sendable {

    /// The token was rejected: expired, revoked, or lacking the scope for this resource.
    ///
    /// GitHub answers 401, or 403 while rate limit budget remains.
    case unauthorized

    /// The rate limit is exhausted.
    ///
    /// GitHub answers 403 with `X-RateLimit-Remaining: 0`, or 429 for a secondary limit.
    /// `resetAt` is the moment the budget refills, when GitHub said.
    ///
    /// - Important: Distinct from ``unauthorized`` on purpose. Both arrive as 403, and a caller
    ///   that retries a rate limit as though it were an auth failure makes the problem worse.
    case rateLimited(resetAt: Date?)

    /// The resource does not exist, or the installation cannot see it.
    ///
    /// - Note: ``GitHubClient/latestRelease(owner:repository:)`` translates this into `nil`
    ///   rather than throwing, because a repository without releases is ordinary.
    case notFound

    /// A status code with no more specific meaning here. Carries a truncated response body.
    case unexpectedStatus(Int, body: String)

    /// The request never produced an HTTP response — DNS, TLS, connection, cancellation.
    case transport(String)

    /// An HTTP response arrived but could not be understood: undecodable JSON,
    /// a non-HTTP response, or an unusable `Link` header.
    case malformedResponse(String)
}

extension GitHubClientError: CustomStringConvertible {

    public var description: String {
        switch self {
        case .unauthorized:
            return "GitHub rejected the token (401/403). It may have expired or lack the required scope."
        case .rateLimited(let resetAt):
            if let resetAt {
                return "GitHub rate limit exhausted. Resets at \(resetAt)."
            } else {
                return "GitHub rate limit exhausted."
            }
        case .notFound:
            return "GitHub returned 404. The resource does not exist, or the installation cannot see it."
        case .unexpectedStatus(let status, let body):
            return "GitHub returned an unexpected status \(status): \(body)"
        case .transport(let message):
            return "The request to GitHub failed before a response arrived: \(message)"
        case .malformedResponse(let message):
            return "The response from GitHub could not be read: \(message)"
        }
    }
}
