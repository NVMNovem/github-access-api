//
//  SetupError.swift
//  github-access-vapor
//
//  Created by Damian Van de Kauter on 19/04/2026.
//

import Foundation

/// Why the SwiftUI setup flow (`gitHubSetup(setup:)` or ``GitHubSetup``) failed.
public enum SetupError: Error {

    /// The URL the app was opened with has no usable `installation_id`: it is missing, not a
    /// positive integer, or does not fit in `Int` on this device.
    ///
    /// The rule is `GitHubSetupCallback`'s, which is the same as github-access-vapor's setup page.
    case invalidInstallationID

    /// Reserved for failures that have no more specific case. Not currently thrown.
    case unknown
}
