//
//  Duration+TimeInterval.swift
//  Utils
//
//  Created by Kamil Misiag on 19/10/2026.
//

import Foundation

extension Duration {
    public var timeInterval: TimeInterval {
        self / .seconds(1)
    }
}
