//
//  PreparedPreview.swift
//  OpenMeteo
//
//  Created by Kamil Misiag on 18/10/2026.
//

#if DEBUG
import SwiftUI

struct PreparedPreview<Content: View>: View {
    private let prepare: () async -> Void
    private let content: () -> Content

    @State private var isPrepared = false

    init(prepare: @escaping () async -> Void, @ViewBuilder content: @escaping () -> Content) {
        self.prepare = prepare
        self.content = content
    }

    var body: some View {
        ZStack {
            if isPrepared {
                content()
            }
        }
        .task {
            await prepare()
            isPrepared = true
        }
    }
}
#endif
