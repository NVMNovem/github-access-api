//
//  GitHubSetupCallbackTests.swift
//  github-access-api
//
//  Created by Damian Van de Kauter on 09/10/2026.
//

import Foundation
import Testing
import GitHubAccessModels

@Suite("GitHubSetupCallback")
struct GitHubSetupCallbackTests {

    private func callback(_ string: String) throws(GitHubSetupCallbackError) -> GitHubSetupCallback {
        try GitHubSetupCallback(url: URL(string: string)!)
    }

    @Test("Parses GitHub's setup redirect")
    func parsesSetupRedirect() throws {
        let parsed = try callback("https://manager.example.com/github/setup?installation_id=12345678&setup_action=install&state=k7Q%2B%2Fx")

        #expect(parsed.installationID == 12_345_678)
        #expect(parsed.setupAction == .install)
        #expect(parsed.state == "k7Q+/x")
    }

    @Test("Parses github-access-vapor's app-scheme hop, which has no setup_action")
    func parsesAppSchemeHop() throws {
        let parsed = try callback("gitassist://github/setup-complete?installation_id=12345678")

        #expect(parsed.installationID == 12_345_678)
        #expect(parsed.setupAction == nil)
        #expect(parsed.state == nil)
    }

    @Test("update and an unknown future action pass through")
    func passesActionsThrough() throws {
        let actual6 = try callback("https://x.test/?installation_id=1&setup_action=update").setupAction
        #expect(actual6 == .update)
        let actual7 = try callback("https://x.test/?installation_id=1&setup_action=transfer").setupAction?.rawValue
        #expect(actual7 == "transfer")
        let actual8 = try callback("https://x.test/?installation_id=1&setup_action=").setupAction
        #expect(actual8 == nil)
    }

    @Test("A request may come without an installation ID")
    func requestWithoutInstallation() throws {
        let parsed = try callback("https://x.test/github/setup?setup_action=request&state=abc")

        #expect(parsed.installationID == nil)
        #expect(parsed.setupAction == .request)
        #expect(parsed.state == "abc")
    }

    @Test("A missing installation ID is rejected for every other action")
    func rejectsMissingID() {
        for url in [
            "https://x.test/github/setup",
            "https://x.test/github/setup?setup_action=install",
            "https://x.test/github/setup?setup_action=update&state=abc",
            "https://x.test/github/setup?installation_id",
        ] {
            #expect(throws: GitHubSetupCallbackError.missingInstallationID) { try callback(url) }
        }
    }

    @Test(
        "Rejects an installation ID the vapor setup page rejects",
        arguments: ["", "abc", "12a", "1.5", "-1", "0", "0x10", " 1", "1 ", "99999999999999999999", "<script>"]
    )
    func rejectsInvalidID(raw: String) {
        #expect(throws: GitHubSetupCallbackError.invalidInstallationID(raw)) {
            try GitHubSetupCallback(queryItems: [URLQueryItem(name: "installation_id", value: raw)])
        }
    }

    @Test("An invalid ID is rejected even on a request")
    func rejectsInvalidIDOnRequest() {
        #expect(throws: GitHubSetupCallbackError.invalidInstallationID("x")) {
            try callback("https://x.test/?installation_id=x&setup_action=request")
        }
    }

    @Test("Accepts what Int64(_:) accepts, as the vapor setup page does, up to Int64.max")
    func acceptsVaporRule() throws {
        let actual9 = try callback("https://x.test/?installation_id=%2B42").installationID
        #expect(actual9 == 42)
        let actual10 = try callback("https://x.test/?installation_id=9223372036854775807").installationID
        #expect(actual10 == .max)
        let actual11 = try callback("https://x.test/?installation_id=007").installationID
        #expect(actual11 == 7)
    }

    @Test("A duplicated parameter is refused, not resolved")
    func rejectsDuplicates() {
        #expect(throws: GitHubSetupCallbackError.duplicateParameter("installation_id")) {
            try callback("https://x.test/?installation_id=1&installation_id=2")
        }
        #expect(throws: GitHubSetupCallbackError.duplicateParameter("state")) {
            try callback("https://x.test/?installation_id=1&state=a&state=b")
        }
        #expect(throws: GitHubSetupCallbackError.duplicateParameter("setup_action")) {
            try callback("https://x.test/?installation_id=1&setup_action=install&setup_action=update")
        }
    }

    @Test("Ignores unknown parameters and treats an empty state as absent")
    func ignoresUnknownParameters() throws {
        let parsed = try callback("https://x.test/?code=zzz&installation_id=3&state=&utm_source=mail")

        #expect(parsed.installationID == 3)
        #expect(parsed.state == nil)
    }

    @Test("The memberwise initializer enforces the same rule")
    func memberwiseInitializerValidates() throws {
        #expect(throws: GitHubSetupCallbackError.invalidInstallationID("0")) {
            try GitHubSetupCallback(installationID: 0)
        }
        #expect(throws: GitHubSetupCallbackError.missingInstallationID) {
            try GitHubSetupCallback(installationID: nil, setupAction: .install)
        }
        let actual12 = try GitHubSetupCallback(installationID: nil, setupAction: .request).installationID
        #expect(actual12 == nil)
    }

    @Test("Round trips through JSON with GitHub's parameter names, and validates on decode")
    func codable() throws {
        let parsed = try callback("https://x.test/?installation_id=12&setup_action=update&state=s")

        let actual13 = try roundTrip(parsed)
        #expect(actual13 == parsed)

        let object = try jsonObject(parsed)
        #expect(object["installation_id"] as? Int == 12)
        #expect(object["setup_action"] as? String == "update")

        #expect(throws: GitHubSetupCallbackError.invalidInstallationID("-4")) {
            try decode(GitHubSetupCallback.self, from: #"{"installation_id":-4}"#)
        }
    }
}
