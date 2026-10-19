//
//  OpenMeteoApp.swift
//  OpenMeteo
//
//  Created by Kamil Misiag on 15/10/2026.
//

import Foundation
import SwiftUI

@main
struct OpenMeteoApp: App {
    @State private var session = AppComposer(logSubsystem: Bundle.main.bundleIdentifier!).makeSession()

    var body: some Scene {
        WindowGroup {
            RootView(session: session)
        }
    }
}
