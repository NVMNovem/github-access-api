//
//  SetupResult.swift
//  github-access-vapor
//
//  Created by Damian Van de Kauter on 19/04/2026.
//

/// What the SwiftUI setup flow reports: the installation ID on success, or the error that stopped it
/// — usually ``SetupError/invalidInstallationID``.
public typealias SetupResult = Result<Int, Error>
