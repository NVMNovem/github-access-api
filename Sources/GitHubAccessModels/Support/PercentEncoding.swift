//
//  PercentEncoding.swift
//  github-access-api
//
//  Created by Damian Van de Kauter on 09/10/2026.
//

/// Percent-encodes everything outside RFC 3986's *unreserved* set (`A–Z a–z 0–9 - . _ ~`).
///
/// Deliberately stricter than `URLComponents.queryItems`, which leaves `+` and other
/// sub-delimiters unencoded. A `+` left raw in a `state` value is read back
/// as a space by form decoders, and the round trip then fails the very check `state` exists for.
/// Encoding every reserved character gives one answer on every platform.
internal enum PercentEncoding {

    internal static func encode(_ string: String) -> String {
        var result = ""
        result.reserveCapacity(string.utf8.count)

        for byte in string.utf8 {
            if isUnreserved(byte) {
                result.unicodeScalars.append(Unicode.Scalar(byte))
            } else {
                result += "%"
                result += hexDigit(byte >> 4)
                result += hexDigit(byte & 0x0F)
            }
        }
        return result
    }

    private static func isUnreserved(_ byte: UInt8) -> Bool {
        switch byte {
        case UInt8(ascii: "A")...UInt8(ascii: "Z"),
             UInt8(ascii: "a")...UInt8(ascii: "z"),
             UInt8(ascii: "0")...UInt8(ascii: "9"),
             UInt8(ascii: "-"), UInt8(ascii: "."), UInt8(ascii: "_"), UInt8(ascii: "~"):
            return true
        default:
            return false
        }
    }

    private static func hexDigit(_ value: UInt8) -> String {
        String(UnicodeScalar(value < 10 ? UInt8(ascii: "0") + value : UInt8(ascii: "A") + value - 10))
    }
}

/// Validation for the identifiers that are spliced into a github.com *path*.
internal enum GitHubIdentifier {

    /// Letters, digits, `-` and `_`. Anything else — `/`, `.`, `?`, `#`, `%`, whitespace — could
    /// move the link to a different page on github.com, so it is refused rather than encoded.
    internal static func isValidSlug(_ string: String) -> Bool {
        !string.isEmpty && string.utf8.count <= 100 && string.utf8.allSatisfy { byte in
            switch byte {
            case UInt8(ascii: "A")...UInt8(ascii: "Z"),
                 UInt8(ascii: "a")...UInt8(ascii: "z"),
                 UInt8(ascii: "0")...UInt8(ascii: "9"),
                 UInt8(ascii: "-"), UInt8(ascii: "_"):
                return true
            default:
                return false
            }
        }
    }

    /// GitHub's rule for user and organization logins: up to 39 letters, digits and hyphens, not
    /// starting with a hyphen.
    internal static func isValidLogin(_ string: String) -> Bool {
        guard let first = string.utf8.first, first != UInt8(ascii: "-"), string.utf8.count <= 39 else {
            return false
        }
        return string.utf8.allSatisfy { byte in
            switch byte {
            case UInt8(ascii: "A")...UInt8(ascii: "Z"),
                 UInt8(ascii: "a")...UInt8(ascii: "z"),
                 UInt8(ascii: "0")...UInt8(ascii: "9"),
                 UInt8(ascii: "-"):
                return true
            default:
                return false
            }
        }
    }
}
