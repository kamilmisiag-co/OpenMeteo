//
//  SampleAppComposer.swift
//  OpenMeteo
//
//  Created by Kamil Misiag on 19/10/2026.
//

#if DEBUG
struct SampleAppComposer: AppComposing {
    func makeSession() -> AppSession {
        PreviewAppFactory().makeSession()
    }
}
#endif
