//
//  LaunchFailureReporting.swift
//  OpenMeteo
//
//  Created by Kamil Misiag on 18/10/2026.
//

protocol LaunchFailureReporting {
    func report(_ error: any Error)
}
