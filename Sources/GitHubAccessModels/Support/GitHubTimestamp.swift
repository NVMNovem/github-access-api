//
//  GitHubTimestamp.swift
//  github-access-api
//
//  Created by Damian Van de Kauter on 09/10/2026.
//

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// Reads and writes the ISO 8601 timestamps GitHub's REST API and webhooks use.
///
/// The models decode a timestamp themselves instead of relying on the decoder's
/// `dateDecodingStrategy`. A plain `JSONDecoder()` defaults to `.deferredToDate`, which expects a
/// number and would fail on every GitHub payload; reading the string here means the models decode
/// the same way whatever decoder the caller set up. A decoder configured with `.iso8601` (as
/// github-access-vapor's webhook route is) still works, because a string is read as a string.
///
/// GitHub writes both `2013-02-27T19:35:32Z` and offsets such as `2017-07-08T16:18:44-04:00`, so
/// both are accepted, with or without fractional seconds.
internal enum GitHubTimestamp {

    private static let plain = Date.ISO8601FormatStyle()
    private static let fractional = Date.ISO8601FormatStyle(includingFractionalSeconds: true)

    internal static func parse(_ string: String) -> Date? {
        if let date = try? plain.parse(string) { return date }
        if let date = try? fractional.parse(string) { return date }
        return nil
    }

    /// Formats in UTC, adding fractional seconds only when the date has them, so that a whole-second
    /// date round trips to exactly the form GitHub sends.
    internal static func format(_ date: Date) -> String {
        let seconds = date.timeIntervalSince1970
        if seconds.rounded(.towardZero) == seconds {
            return plain.format(date)
        }
        return fractional.format(date)
    }
}

extension KeyedDecodingContainer {

    /// Decodes a GitHub timestamp, accepting an ISO 8601 string or — for data this package encoded
    /// with a non-default strategy — whatever the decoder's own date strategy reads.
    internal func decodeGitHubDateIfPresent(forKey key: Key) throws -> Date? {
        guard contains(key), try !decodeNil(forKey: key) else { return nil }

        if let string = try? decode(String.self, forKey: key) {
            guard let date = GitHubTimestamp.parse(string) else {
                throw DecodingError.dataCorruptedError(
                    forKey: key, in: self,
                    debugDescription: "Expected an ISO 8601 timestamp, found \"\(string)\"."
                )
            }
            return date
        }

        return try decode(Date.self, forKey: key)
    }

    /// Decodes a URL written as a string, rejecting one `URL(string:)` cannot parse.
    internal func decodeURLIfPresent(forKey key: Key) throws -> URL? {
        guard let string = try decodeIfPresent(String.self, forKey: key) else { return nil }
        guard let url = URL(string: string) else {
            throw DecodingError.dataCorruptedError(
                forKey: key, in: self, debugDescription: "Expected a URL, found \"\(string)\"."
            )
        }
        return url
    }

    internal func decodeURL(forKey key: Key) throws -> URL {
        guard let url = try decodeURLIfPresent(forKey: key) else {
            throw DecodingError.keyNotFound(
                key, .init(codingPath: codingPath, debugDescription: "Missing URL for \(key.stringValue).")
            )
        }
        return url
    }
}

extension KeyedEncodingContainer {

    internal mutating func encodeGitHubDateIfPresent(_ date: Date?, forKey key: Key) throws {
        guard let date else { return }
        try encode(GitHubTimestamp.format(date), forKey: key)
    }

    /// Encodes a URL as its absolute string. `JSONEncoder` does this for `URL` already, but other
    /// encoders write a keyed `{"relative": …}` form that GitHub would not understand.
    internal mutating func encodeURLIfPresent(_ url: URL?, forKey key: Key) throws {
        guard let url else { return }
        try encode(url.absoluteString, forKey: key)
    }
}
