//
//  GitHubHTTPTransport.swift
//  github-access-api
//

import Foundation

/// A single HTTP request, reduced to what this package sends.
///
/// Deliberately not `URLRequest`: keeping the seam on plain value types means the tests
/// never touch `URLSession`, and `FoundationNetworking` stays confined to one file.
internal struct GitHubHTTPRequest: Sendable, Hashable {

    internal var url: URL
    internal var method: String
    internal var headers: [String: String]

    internal init(url: URL, method: String = "GET", headers: [String: String] = [:]) {
        self.url = url
        self.method = method
        self.headers = headers
    }

    /// Case-insensitive header lookup, matching HTTP semantics.
    internal func header(_ name: String) -> String? {
        GitHubHTTPResponse.value(forHeader: name, in: self.headers)
    }
}

/// A single HTTP response, reduced to what this package reads.
internal struct GitHubHTTPResponse: Sendable {

    internal var statusCode: Int
    internal var headers: [String: String]
    internal var body: Data

    internal init(statusCode: Int, headers: [String: String] = [:], body: Data = Data()) {
        self.statusCode = statusCode
        self.headers = headers
        self.body = body
    }

    /// Case-insensitive header lookup, matching HTTP semantics.
    internal func header(_ name: String) -> String? {
        Self.value(forHeader: name, in: self.headers)
    }

    internal static func value(forHeader name: String, in headers: [String: String]) -> String? {
        if let exact = headers[name] { return exact }

        let lowercased = name.lowercased()
        return headers.first { $0.key.lowercased() == lowercased }?.value
    }
}

/// The seam ``GitHubClient`` sends requests through.
///
/// Production uses ``URLSessionTransport``; tests substitute a stub so no test touches the network.
internal protocol GitHubHTTPTransport: Sendable {

    func send(_ request: GitHubHTTPRequest) async throws -> GitHubHTTPResponse
}
