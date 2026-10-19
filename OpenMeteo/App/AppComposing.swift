//
//  AppComposing.swift
//  OpenMeteo
//
//  Created by Kamil Misiag on 18/10/2026.
//

protocol AppComposing {
    func makeSession() throws -> AppSession
}
