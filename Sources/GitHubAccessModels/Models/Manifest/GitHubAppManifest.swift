//
//  GitHubAppManifest.swift
//  github-access-api
//
//  Created by Damian Van de Kauter on 09/10/2026.
//

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// A GitHub App manifest: the settings of an App to create, so that an administrator can register
/// it in one step instead of filling in GitHub's form by hand.
///
/// The flow, per GitHub's
/// [manifest documentation](https://docs.github.com/apps/sharing-github-apps/registering-a-github-app-from-a-manifest):
///
/// 1. The browser `POST`s a form with one field, `manifest`, holding this model as JSON, to
///    ``registration(for:state:)``'s ``Registration/url``. GitHub shows the App for review.
/// 2. After the administrator confirms, GitHub redirects to ``redirectURL`` with `code` and the
///    `state` you sent. Check the `state`.
/// 3. The server exchanges the code within an hour with `POST /app-manifests/{code}/conversions`,
///    which answers with a ``GitHubAppManifestConversion`` — the App's ID, private key and secrets.
///
/// ```swift
/// let manifest = GitHubAppManifest.serverManager(
///     name: "Funico Server Manager",
///     url: URL(string: "https://manager.example.com")!,
///     webhookURL: URL(string: "https://manager.example.com/github/webhook")!,
///     redirectURL: URL(string: "https://manager.example.com/github/manifest/callback")!,
///     setupURL: URL(string: "https://manager.example.com/github/setup")!
/// )
/// let registration = try manifest.registration(for: .organization("funico"), state: "k7Q")
/// // POST registration.formURLEncodedBody to registration.url from the browser.
/// ```
///
/// Keys are encoded in GitHub's snake_case. Optional settings that are `nil` are left out, so GitHub
/// applies its own default.
public struct GitHubAppManifest: Codable, Sendable, Hashable {

    /// The App's name. Must be unique across GitHub; GitHub lets the administrator change it on the
    /// review page. `nil` leaves it to the administrator.
    public var name: String?

    /// The App's homepage. The one field GitHub requires.
    public var url: URL

    /// A description shown on the App's page.
    public var description: String?

    /// Where GitHub delivers webhooks. `nil` creates an App without a webhook.
    public var hookAttributes: HookAttributes?

    /// Where GitHub redirects, with `code` and `state`, after the App is created. Must be a page your
    /// server handles: it is where the code is exchanged.
    public var redirectURL: URL?

    /// The user-authorization callback URLs, at most 10. Empty when the App never signs users in.
    public var callbackURLs: [URL]

    /// Where GitHub redirects after someone installs the App, with `installation_id`,
    /// `setup_action` and the install link's `state` — read by ``GitHubSetupCallback``.
    public var setupURL: URL?

    /// Whether any account may install the App (`true`) or only the account that owns it
    /// (`false`). Encoded as `public`.
    public var isPublic: Bool

    /// The permissions the App asks for, keyed by permission name (`contents`, `metadata`, …).
    /// Ask for as little as possible: an installation grants exactly this.
    public var defaultPermissions: [String: GitHubPermissionLevel]

    /// The webhook events the App subscribes to, such as `release`.
    ///
    /// Each event needs a matching permission, and GitHub rejects the manifest otherwise.
    /// `installation` and `installation_repositories` are delivered to every App automatically and
    /// cannot be listed here.
    public var defaultEvents: [String]

    /// Whether installing also asks the installer to authorize the App to act as them.
    public var requestOAuthOnInstall: Bool?

    /// Whether GitHub also redirects to ``setupURL`` when an installation is *updated*, for example
    /// when repositories are added or removed. Needs ``setupURL``.
    public var setupOnUpdate: Bool?

    /// Where and how GitHub delivers the App's webhooks: the manifest's `hook_attributes`.
    public struct HookAttributes: Codable, Sendable, Hashable {

        /// The URL GitHub `POST`s webhook deliveries to.
        public var url: URL

        /// Whether deliveries are sent. GitHub's default is `true`.
        public var active: Bool?

        /// Creates hook attributes.
        ///
        /// - Parameters:
        ///   - url: The URL GitHub `POST`s webhook deliveries to.
        ///   - active: Whether deliveries are sent. `nil` uses GitHub's default, `true`.
        public init(url: URL, active: Bool? = nil) {
            self.url = url
            self.active = active
        }

        private enum CodingKeys: String, CodingKey {
            case url
            case active
        }

        /// Decodes `url` and `active`.
        public init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)

            self.url = try container.decodeURL(forKey: .url)
            self.active = try container.decodeIfPresent(Bool.self, forKey: .active)
        }

        /// Encodes `url` as a string and `active` when set.
        public func encode(to encoder: any Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)

            try container.encodeURLIfPresent(url, forKey: .url)
            try container.encodeIfPresent(active, forKey: .active)
        }
    }

    /// Who will own the App, which decides where the manifest is posted.
    public enum Owner: Sendable, Hashable {

        /// The signed-in user's personal account: `https://github.com/settings/apps/new`.
        case user

        /// An organization, by login: `https://github.com/organizations/<org>/settings/apps/new`.
        /// The signed-in user must be allowed to manage the organization's Apps.
        case organization(String)
    }

    /// Where and what to `POST` to register an App from a manifest.
    ///
    /// GitHub only accepts the manifest as a browser form submission — the administrator has to be
    /// signed in on github.com and confirm — so a server cannot do this step on their behalf. Render
    /// an HTML `<form method="post">` with ``url`` as its action and a single field named
    /// ``formFieldName`` holding ``manifestJSON``, or send ``formURLEncodedBody`` from the browser.
    public struct Registration: Sendable, Hashable {

        /// The form's action: the registration page with the `state` in its query.
        public let url: URL

        /// The manifest, encoded as compact JSON with sorted keys.
        public let manifestJSON: String

        /// The `state` GitHub will echo back on ``GitHubAppManifest/redirectURL``.
        public let state: String

        /// The name of the form field GitHub reads the manifest from: `manifest`.
        public var formFieldName: String { "manifest" }

        /// The whole form as an `application/x-www-form-urlencoded` body: `manifest=<encoded JSON>`.
        public var formURLEncodedBody: String {
            "\(formFieldName)=\(PercentEncoding.encode(manifestJSON))"
        }
    }

    /// Creates a manifest.
    ///
    /// - Parameters:
    ///   - name: The App's name.
    ///   - url: The App's homepage. Required by GitHub.
    ///   - description: A description shown on the App's page.
    ///   - hookAttributes: Where GitHub delivers webhooks. `nil` for no webhook.
    ///   - redirectURL: Where GitHub redirects with the code after the App is created.
    ///   - callbackURLs: The user-authorization callback URLs, at most 10.
    ///   - setupURL: Where GitHub redirects after an installation.
    ///   - isPublic: Whether any account may install the App.
    ///   - defaultPermissions: The permissions the App asks for.
    ///   - defaultEvents: The webhook events the App subscribes to.
    ///   - requestOAuthOnInstall: Whether installing also authorizes the App as the installer.
    ///   - setupOnUpdate: Whether updates also redirect to `setupURL`.
    public init(
        name: String? = nil,
        url: URL,
        description: String? = nil,
        hookAttributes: HookAttributes? = nil,
        redirectURL: URL? = nil,
        callbackURLs: [URL] = [],
        setupURL: URL? = nil,
        isPublic: Bool = false,
        defaultPermissions: [String: GitHubPermissionLevel] = [:],
        defaultEvents: [String] = [],
        requestOAuthOnInstall: Bool? = nil,
        setupOnUpdate: Bool? = nil
    ) {
        self.name = name
        self.url = url
        self.description = description
        self.hookAttributes = hookAttributes
        self.redirectURL = redirectURL
        self.callbackURLs = callbackURLs
        self.setupURL = setupURL
        self.isPublic = isPublic
        self.defaultPermissions = defaultPermissions
        self.defaultEvents = defaultEvents
        self.requestOAuthOnInstall = requestOAuthOnInstall
        self.setupOnUpdate = setupOnUpdate
    }

    /// The least-privilege App the Funico Server Manager needs: it reads releases and their assets,
    /// and is told when one is published.
    ///
    /// - `contents: read` — the `release` webhook and the release and asset REST endpoints all sit
    ///   under the Contents permission. Read is enough to list releases, download assets
    ///   and clone; nothing the Manager does writes to a repository.
    /// - `metadata: read` — mandatory for every App; GitHub adds it anyway, and stating it keeps the
    ///   review page honest.
    /// - `release` events — so a published release reaches the Manager without polling.
    /// - `installation` and `installation_repositories` events are *not* listed: GitHub delivers
    ///   them to every App regardless, and they are not events an App subscribes to.
    /// - Private (`public: false`), because only Funico's own account installs it.
    /// - `setup_on_update: true` when a `setupURL` is given, so a change to the installation's
    ///   repository selection comes back through the same setup flow as the install.
    ///
    /// - Parameters:
    ///   - name: The App's name, unique across GitHub.
    ///   - url: The Manager's homepage.
    ///   - webhookURL: Where the Manager API receives webhooks.
    ///   - redirectURL: Where the Manager API exchanges the manifest code.
    ///   - setupURL: Where the Manager API completes an installation, or `nil` for none.
    ///   - description: A description shown on the App's page.
    /// - Returns: The manifest.
    public static func serverManager(
        name: String,
        url: URL,
        webhookURL: URL,
        redirectURL: URL,
        setupURL: URL? = nil,
        description: String? = nil
    ) -> GitHubAppManifest {
        GitHubAppManifest(
            name: name,
            url: url,
            description: description,
            hookAttributes: HookAttributes(url: webhookURL, active: true),
            redirectURL: redirectURL,
            setupURL: setupURL,
            isPublic: false,
            defaultPermissions: [
                "contents": .read,
                "metadata": .read,
            ],
            defaultEvents: ["release"],
            requestOAuthOnInstall: false,
            setupOnUpdate: setupURL == nil ? nil : true
        )
    }

    /// Encodes the manifest as the compact, key-sorted JSON GitHub's form expects.
    ///
    /// - Returns: The JSON string.
    /// - Throws: An `EncodingError` if encoding fails.
    public func jsonString() throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        return String(decoding: try encoder.encode(self), as: UTF8.self)
    }

    /// Builds the form submission that registers this App.
    ///
    /// - Parameters:
    ///   - owner: Whose account will own the App.
    ///   - state: A fresh, unguessable, single-use value bound to the administrator's session.
    ///     GitHub echoes it on ``redirectURL``; refuse a redirect whose `state` you did not issue.
    /// - Returns: The registration URL and the form's content.
    /// - Throws: ``GitHubLinkError/missingState`` for an empty `state`,
    ///   ``GitHubLinkError/invalidOrganization(_:)`` for an invalid organization login, or an
    ///   `EncodingError` if the manifest cannot be encoded.
    public func registration(for owner: Owner = .user, state: String) throws -> Registration {
        guard !state.isEmpty else { throw GitHubLinkError.missingState }

        let path: String
        switch owner {
        case .user:
            path = "/settings/apps/new"
        case .organization(let login):
            guard GitHubIdentifier.isValidLogin(login) else {
                throw GitHubLinkError.invalidOrganization(login)
            }
            path = "/organizations/\(login)/settings/apps/new"
        }

        guard let url = URL(string: "https://github.com\(path)?state=\(PercentEncoding.encode(state))") else {
            throw GitHubLinkError.missingState
        }

        return Registration(url: url, manifestJSON: try jsonString(), state: state)
    }

    private enum CodingKeys: String, CodingKey {
        case name
        case url
        case description
        case hookAttributes = "hook_attributes"
        case redirectURL = "redirect_url"
        case callbackURLs = "callback_urls"
        case setupURL = "setup_url"
        case isPublic = "public"
        case defaultPermissions = "default_permissions"
        case defaultEvents = "default_events"
        case requestOAuthOnInstall = "request_oauth_on_install"
        case setupOnUpdate = "setup_on_update"
    }

    /// Decodes a manifest. Only `url` is required.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.name = try container.decodeIfPresent(String.self, forKey: .name)
        self.url = try container.decodeURL(forKey: .url)
        self.description = try container.decodeIfPresent(String.self, forKey: .description)
        self.hookAttributes = try container.decodeIfPresent(HookAttributes.self, forKey: .hookAttributes)
        self.redirectURL = try container.decodeURLIfPresent(forKey: .redirectURL)
        self.callbackURLs = try (container.decodeIfPresent([String].self, forKey: .callbackURLs) ?? []).map { string in
            guard let url = URL(string: string) else {
                throw DecodingError.dataCorruptedError(
                    forKey: .callbackURLs, in: container, debugDescription: "Expected a URL, found \"\(string)\"."
                )
            }
            return url
        }
        self.setupURL = try container.decodeURLIfPresent(forKey: .setupURL)
        self.isPublic = try container.decodeIfPresent(Bool.self, forKey: .isPublic) ?? false
        self.defaultPermissions = try container.decodeIfPresent([String: GitHubPermissionLevel].self, forKey: .defaultPermissions) ?? [:]
        self.defaultEvents = try container.decodeIfPresent([String].self, forKey: .defaultEvents) ?? []
        self.requestOAuthOnInstall = try container.decodeIfPresent(Bool.self, forKey: .requestOAuthOnInstall)
        self.setupOnUpdate = try container.decodeIfPresent(Bool.self, forKey: .setupOnUpdate)
    }

    /// Encodes with GitHub's manifest keys. URLs are written as strings; `nil` settings and an empty
    /// `callback_urls` are left out.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encodeIfPresent(name, forKey: .name)
        try container.encodeURLIfPresent(url, forKey: .url)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encodeIfPresent(hookAttributes, forKey: .hookAttributes)
        try container.encodeURLIfPresent(redirectURL, forKey: .redirectURL)
        if !callbackURLs.isEmpty {
            try container.encode(callbackURLs.map(\.absoluteString), forKey: .callbackURLs)
        }
        try container.encodeURLIfPresent(setupURL, forKey: .setupURL)
        try container.encode(isPublic, forKey: .isPublic)
        try container.encode(defaultPermissions, forKey: .defaultPermissions)
        try container.encode(defaultEvents, forKey: .defaultEvents)
        try container.encodeIfPresent(requestOAuthOnInstall, forKey: .requestOAuthOnInstall)
        try container.encodeIfPresent(setupOnUpdate, forKey: .setupOnUpdate)
    }
}
