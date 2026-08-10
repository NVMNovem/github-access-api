//
//  GitHubClient.swift
//  github-access-api
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// A read-only client for the parts of the GitHub REST API a deploy agent needs:
/// which repositories an App installation can see, and what their releases are.
///
/// ```swift
/// let client = GitHubClient(
///     token: { try await tokenService.installationToken() },
///     userAgent: "funico-server-manager/1.0"
/// )
///
/// for repository in try await client.installationRepositories() {
///     let release = try await client.latestRelease(
///         owner: repository.owner,
///         repository: repository.name
///     )
///     print(repository.fullName, release?.tagName ?? "no releases")
/// }
/// ```
///
/// Every method is read-only; nothing here writes to GitHub. Minting the token is out of
/// scope and belongs to whatever service holds the App's private key.
public struct GitHubClient: Sendable {

    /// The API version sent as `X-GitHub-Api-Version` on every request.
    public static let apiVersion: String = "2022-11-28"

    /// `https://api.github.com`.
    public static let defaultBaseURL: URL = URL(string: "https://api.github.com")!

    /// GitHub's maximum, and worth asking for: the default of 30 truncates silently.
    private static let pageSize: Int = 100

    /// A malformed `Link` header could point a page at itself. Bound the walk so a
    /// long-running agent cannot spin forever.
    private static let maximumPageCount: Int = 1_000

    private let token: @Sendable () async throws -> String
    private let userAgent: String
    private let transport: any GitHubHTTPTransport
    private let baseURL: URL

    /// Creates a client.
    ///
    /// - Parameters:
    ///   - token: Produces the token for a request. Called once per HTTP request — including
    ///     once per page while paginating — and never cached by the client.
    ///   - userAgent: Sent as `User-Agent`. GitHub rejects requests without one. Identify the
    ///     calling application, for example `funico-server-manager/1.0`.
    ///   - session: The session requests go out on. Defaults to `URLSession.shared`.
    ///
    /// - Important: The token is a closure rather than a `String` because an installation token
    ///   is valid for one hour while an agent runs for weeks. A client holding a `String` passes
    ///   every test and fails in production on hour two.
    public init(
        token: @escaping @Sendable () async throws -> String,
        userAgent: String,
        session: URLSession = .shared
    ) {
        self.init(
            token: token,
            userAgent: userAgent,
            transport: URLSessionTransport(session: session)
        )
    }

    /// Creates a client over an arbitrary transport. Used by the tests to stay off the network.
    internal init(
        token: @escaping @Sendable () async throws -> String,
        userAgent: String,
        transport: any GitHubHTTPTransport,
        baseURL: URL = GitHubClient.defaultBaseURL
    ) {
        self.token = token
        self.userAgent = userAgent
        self.transport = transport
        self.baseURL = baseURL
    }

    // MARK: - Endpoints

    /// Every repository the installation can see, across all pages.
    ///
    /// `GET /installation/repositories`
    ///
    /// - Important: Paginated. GitHub returns 30 repositories per page by default and gives no
    ///   hint that more exist beyond the `Link` header, so a single-request implementation
    ///   returns a truncated list without failing.
    public func installationRepositories() async throws -> [GitHubRepository] {
        var url = try self.makeURL(path: "/installation/repositories")
        var repositories: [GitHubRepository] = []

        for _ in 0..<Self.maximumPageCount {
            let response = try await self.send(url)
            let page = try self.decode(InstallationRepositoriesPage.self, from: response)
            repositories.append(contentsOf: page.repositories)

            guard let next = self.nextPageURL(from: response) else { return repositories }
            url = next
        }

        throw GitHubClientError.malformedResponse(
            "Pagination did not terminate after \(Self.maximumPageCount) pages of /installation/repositories."
        )
    }

    /// Every release of a repository, across all pages, newest first.
    ///
    /// `GET /repos/{owner}/{repo}/releases`
    ///
    /// Includes drafts and pre-releases; filter on ``GitHubRelease/isDraft`` and
    /// ``GitHubRelease/isPrerelease`` if that matters to the caller.
    ///
    /// - Parameters:
    ///   - owner: The user or organisation login, for example `Funico-NV`.
    ///   - repository: The repository name without its owner.
    public func releases(owner: String, repository: String) async throws -> [GitHubRelease] {
        var url = try self.makeURL(path: "/repos/\(self.escape(owner))/\(self.escape(repository))/releases")
        var releases: [GitHubRelease] = []

        for _ in 0..<Self.maximumPageCount {
            let response = try await self.send(url)
            releases.append(contentsOf: try self.decode([GitHubRelease].self, from: response))

            guard let next = self.nextPageURL(from: response) else { return releases }
            url = next
        }

        throw GitHubClientError.malformedResponse(
            "Pagination did not terminate after \(Self.maximumPageCount) pages of releases for \(owner)/\(repository)."
        )
    }

    /// The latest published release, or `nil` when the repository has none.
    ///
    /// `GET /repos/{owner}/{repo}/releases/latest`
    ///
    /// GitHub excludes drafts and pre-releases from this endpoint.
    ///
    /// - Returns: `nil` when GitHub answers 404. A repository without releases is the common
    ///   case, not a failure, so it is not thrown.
    public func latestRelease(owner: String, repository: String) async throws -> GitHubRelease? {
        let url = try self.makeURL(
            path: "/repos/\(self.escape(owner))/\(self.escape(repository))/releases/latest",
            paginated: false
        )

        do {
            return try self.decode(GitHubRelease.self, from: try await self.send(url))
        } catch GitHubClientError.notFound {
            return nil
        }
    }

    // MARK: - Requests

    private func send(_ url: URL) async throws -> GitHubHTTPResponse {
        // Minted per request: an installation token outlives neither the hour nor the agent.
        let token = try await self.token()

        let request = GitHubHTTPRequest(
            url: url,
            method: "GET",
            headers: [
                "Authorization": "Bearer \(token)",
                "Accept": "application/vnd.github+json",
                "X-GitHub-Api-Version": Self.apiVersion,
                "User-Agent": self.userAgent,
            ]
        )

        let response: GitHubHTTPResponse
        do {
            response = try await self.transport.send(request)
        } catch let error as GitHubClientError {
            throw error
        } catch {
            throw GitHubClientError.transport(String(describing: error))
        }

        try Self.validate(response)
        return response
    }

    private func nextPageURL(from response: GitHubHTTPResponse) -> URL? {
        guard let link = response.header("Link") else { return nil }

        return LinkHeader.nextPageURL(in: link)
    }

    private func makeURL(path: String, paginated: Bool = true) throws -> URL {
        guard var components = URLComponents(url: self.baseURL, resolvingAgainstBaseURL: false) else {
            throw GitHubClientError.malformedResponse("The base URL \(self.baseURL) could not be read.")
        }

        components.path += path
        if paginated {
            components.queryItems = [URLQueryItem(name: "per_page", value: String(Self.pageSize))]
        }

        guard let url = components.url else {
            throw GitHubClientError.malformedResponse("Could not build a URL for \(path).")
        }

        return url
    }

    private func escape(_ pathComponent: String) -> String {
        pathComponent.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? pathComponent
    }

    // MARK: - Responses

    private func decode<T: Decodable>(_ type: T.Type, from response: GitHubHTTPResponse) throws -> T {
        do {
            return try Self.makeDecoder().decode(type, from: response.body)
        } catch {
            throw GitHubClientError.malformedResponse(String(describing: error))
        }
    }

    /// Built per call because `JSONDecoder` is not `Sendable`.
    private static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    private static func validate(_ response: GitHubHTTPResponse) throws {
        switch response.statusCode {
        case 200..<300:
            return

        case 401:
            throw GitHubClientError.unauthorized

        case 403:
            // GitHub answers 403 for both an exhausted rate limit and a rejected token.
            // Only the remaining-budget header tells them apart.
            if self.isRateLimited(response) {
                throw GitHubClientError.rateLimited(resetAt: self.rateLimitReset(of: response))
            }
            throw GitHubClientError.unauthorized

        case 404:
            throw GitHubClientError.notFound

        case 429:
            // Secondary rate limits arrive as 429.
            throw GitHubClientError.rateLimited(resetAt: self.rateLimitReset(of: response))

        default:
            throw GitHubClientError.unexpectedStatus(
                response.statusCode,
                body: self.bodyPreview(of: response)
            )
        }
    }

    private static func isRateLimited(_ response: GitHubHTTPResponse) -> Bool {
        guard let remaining = response.header("X-RateLimit-Remaining") else { return false }

        return Int(remaining.trimmingCharacters(in: .whitespaces)) == 0
    }

    private static func rateLimitReset(of response: GitHubHTTPResponse) -> Date? {
        if let reset = response.header("X-RateLimit-Reset"),
           let seconds = TimeInterval(reset.trimmingCharacters(in: .whitespaces)) {
            return Date(timeIntervalSince1970: seconds)
        }

        // Secondary limits send Retry-After, in seconds from now, instead.
        if let retryAfter = response.header("Retry-After"),
           let seconds = TimeInterval(retryAfter.trimmingCharacters(in: .whitespaces)) {
            return Date().addingTimeInterval(seconds)
        }

        return nil
    }

    private static func bodyPreview(of response: GitHubHTTPResponse) -> String {
        let body = String(data: response.body, encoding: .utf8) ?? "<\(response.body.count) bytes>"
        guard body.count > 2_048 else { return body }

        return String(body.prefix(2_048)) + "…"
    }
}

/// `GET /installation/repositories` wraps its array, unlike most list endpoints.
private struct InstallationRepositoriesPage: Decodable {

    let repositories: [GitHubRepository]
}
