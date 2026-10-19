//
//  RequestBody.swift
//  Networking
//
//  Created by Kamil Misiag on 16/10/2026.
//

import Foundation

public enum RequestBody: Sendable {
    case data(Data, contentType: String)
    case encodable(any Encodable & Sendable)
}
