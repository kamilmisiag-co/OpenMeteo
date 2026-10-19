//
//  ActivityDetailFactor.swift
//  OpenMeteo
//
//  Created by Kamil Misiag on 18/10/2026.
//

import Logic

struct ActivityDetailFactor: Identifiable, Hashable {
    let kind: Factor.Kind
    let title: String
    let summary: String
    let value: String?
    let helps: Bool

    var id: Factor.Kind { kind }
}
