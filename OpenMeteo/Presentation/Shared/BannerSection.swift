//
//  BannerSection.swift
//  OpenMeteo
//
//  Created by Kamil Misiag on 19/10/2026.
//

import DesignSystem
import SwiftUI

struct BannerSection: View {
    let banner: BannerContent?

    var body: some View {
        if let banner {
            Section {
                StatusBanner(kind: banner.kind, message: banner.message)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
            }
        }
    }
}
