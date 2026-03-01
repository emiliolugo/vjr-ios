//
//  ProfileView.swift
//  vjr.
//
//  Created by Emilio Lugo on 2/28/26.
//

import SwiftUI

struct ProfileView: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 0) {
            TabHeader {
                Text("username")
                    .font(.headline)
            }

            Text("Profile")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(AppTheme.background(for: colorScheme))
        .foregroundStyle(AppTheme.primaryText(for: colorScheme))
    }
}

#Preview {
    ProfileView()
}
