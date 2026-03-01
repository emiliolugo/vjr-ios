//
//  FriendsView.swift
//  vjr.
//
//  Created by Emilio Lugo on 2/28/26.
//

import SwiftUI

struct FriendsView: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Text("Friends")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AppTheme.background(for: colorScheme))
            .foregroundStyle(AppTheme.primaryText(for: colorScheme))
    }
}

#Preview {
    FriendsView()
}
