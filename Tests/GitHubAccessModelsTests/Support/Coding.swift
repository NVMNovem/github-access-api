//
//  Coding.swift
//  github-access-api
//
//  Created by Damian Van de Kauter on 09/10/2026.
//

import Foundation
import Testing

/// Decodes `json` with a plain `JSONDecoder()` — no date strategy, as a client that knows nothing
/// about GitHub would set one up.
func decode<T: Decodable>(_ type: T.Type, from json: String) throws -> T {
    try JSONDecoder().decode(T.self, from: json.utf8Data)
}

/// Encodes `value` with a plain `JSONEncoder()` and decodes the result again.
func roundTrip<T: Codable>(_ value: T) throws -> T {
    try JSONDecoder().decode(T.self, from: JSONEncoder().encode(value))
}

/// The JSON object `value` encodes to, for checking keys.
func jsonObject<T: Encodable>(_ value: T) throws -> [String: Any] {
    let data = try JSONEncoder().encode(value)
    return try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
}
