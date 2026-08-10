//
//  LinkHeader.swift
//  github-access-api
//

import Foundation

/// Parser for the RFC 8288 `Link` header GitHub paginates with.
///
/// A response looks like:
///
/// ```
/// Link: <https://api.github.com/installation/repositories?per_page=100&page=2>; rel="next",
///       <https://api.github.com/installation/repositories?per_page=100&page=5>; rel="last"
/// ```
internal enum LinkHeader {

    /// Maps each `rel` to its URL. Relation names are lowercased; the last duplicate wins.
    ///
    /// Splitting on commas would be wrong — URLs carry commas in query values — so each link
    /// is read as an angle-bracketed URL followed by parameters running up to the next `<`.
    internal static func links(in header: String) -> [String: URL] {
        var links: [String: URL] = [:]
        var remainder = Substring(header)

        while let open = remainder.firstIndex(of: "<"),
              let close = remainder[open...].firstIndex(of: ">") {

            let urlString = remainder[remainder.index(after: open)..<close]
                .trimmingCharacters(in: .whitespacesAndNewlines)

            let parameters = remainder[remainder.index(after: close)...]
            let nextOpen = parameters.firstIndex(of: "<")
            let parameterSection = nextOpen.map { parameters[..<$0] } ?? parameters[...]
            remainder = nextOpen.map { parameters[$0...] } ?? Substring()

            if let relation = self.relation(in: parameterSection), let url = URL(string: urlString) {
                links[relation.lowercased()] = url
            }
        }

        return links
    }

    /// The URL of the next page, or `nil` when this is the last page.
    internal static func nextPageURL(in header: String) -> URL? {
        self.links(in: header)["next"]
    }

    /// Characters surrounding a parameter token: whitespace, the separating comma, and quotes.
    private static let tokenTrim = CharacterSet(charactersIn: " \t\r\n,\"")

    private static func relation(in parameters: Substring) -> String? {
        for parameter in parameters.split(separator: ";") {
            let pair = parameter.split(separator: "=", maxSplits: 1)
            guard pair.count == 2 else { continue }

            let key = pair[0].trimmingCharacters(in: self.tokenTrim)
            guard key.lowercased() == "rel" else { continue }

            let value = pair[1].trimmingCharacters(in: self.tokenTrim)
            return value.isEmpty ? nil : value
        }

        return nil
    }
}
