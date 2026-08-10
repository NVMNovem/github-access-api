//
//  URLSessionTransport.swift
//  github-access-api
//

import Foundation
#if canImport(FoundationNetworking)
// On Linux, URLSession lives in FoundationNetworking rather than Foundation.
import FoundationNetworking
#endif

/// The production ``GitHubHTTPTransport``, backed by `URLSession`.
///
/// The only file in this target that knows `URLSession` exists.
///
/// - Note: `@unchecked Sendable` because `URLSession` is not annotated `Sendable` on every
///   platform this package builds for. It is safe to share; only immutable state is stored.
internal struct URLSessionTransport: GitHubHTTPTransport, @unchecked Sendable {

    private let session: URLSession

    internal init(session: URLSession) {
        self.session = session
    }

    internal func send(_ request: GitHubHTTPRequest) async throws -> GitHubHTTPResponse {
        let urlRequest = Self.makeURLRequest(from: request)

        #if canImport(FoundationNetworking)
        // The response is assembled inside the completion handler so that only the
        // Sendable GitHubHTTPResponse crosses the continuation.
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<GitHubHTTPResponse, any Error>) in
            let task = self.session.dataTask(with: urlRequest) { data, response, error in
                if let error {
                    continuation.resume(throwing: GitHubClientError.transport(String(describing: error)))
                    return
                }

                do {
                    continuation.resume(returning: try Self.makeResponse(data: data, response: response))
                } catch {
                    continuation.resume(throwing: error)
                }
            }
            task.resume()
        }
        #else
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await self.session.data(for: urlRequest)
        } catch {
            throw GitHubClientError.transport(String(describing: error))
        }

        return try Self.makeResponse(data: data, response: response)
        #endif
    }

    private static func makeURLRequest(from request: GitHubHTTPRequest) -> URLRequest {
        var urlRequest = URLRequest(url: request.url)
        urlRequest.httpMethod = request.method

        for (name, value) in request.headers {
            urlRequest.setValue(value, forHTTPHeaderField: name)
        }

        return urlRequest
    }

    private static func makeResponse(data: Data?, response: URLResponse?) throws -> GitHubHTTPResponse {
        guard let http = response as? HTTPURLResponse else {
            throw GitHubClientError.malformedResponse("URLSession returned a response that was not an HTTP response.")
        }

        var headers: [String: String] = [:]
        headers.reserveCapacity(http.allHeaderFields.count)
        for (name, value) in http.allHeaderFields {
            guard let name = name as? String else { continue }
            headers[name] = value as? String ?? String(describing: value)
        }

        return GitHubHTTPResponse(
            statusCode: http.statusCode,
            headers: headers,
            body: data ?? Data()
        )
    }
}
