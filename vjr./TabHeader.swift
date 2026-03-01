//
//  TabHeader.swift
//  vjr.
//
//  Created by Emilio Lugo on 2/28/26.
//

import SwiftUI

struct TabHeader<Content: View>: View {
    @ViewBuilder let content: Content
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        content
            .frame(maxWidth: .infinity, minHeight: 44)
            .background(AppTheme.surface(for: colorScheme))
            .foregroundStyle(AppTheme.primaryText(for: colorScheme))
            .shadow(color: .black.opacity(0.06), radius: 2, x: 0, y: 1)
    }
}
