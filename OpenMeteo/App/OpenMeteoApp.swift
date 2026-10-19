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
    @State private var session = Self.makeSession()

    private static func makeSession() -> AppSession {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains(AppStandard.sampleDataArgument) {
            return PreviewAppFactory().makeSession()
        }
        #endif
        return AppComposer(logSubsystem: Bundle.main.bundleIdentifier!).makeSession()
    }

    var body: some Scene {
        WindowGroup {
            RootView(session: session)
        }
    }
}
