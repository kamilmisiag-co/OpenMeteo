//
//  SearchFailure+Display.swift
//  OpenMeteo
//
//  Created by Kamil Misiag on 18/10/2026.
//

import Foundation
import Logic

extension SearchFailure {
    var message: LocalizedStringResource {
        switch self {
        case .offline: .searchUnavailableOfflineMessage
        case .unavailable: .searchUnavailableServiceMessage
        }
    }
}
