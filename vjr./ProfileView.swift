//
//  ProfileView.swift
//  vjr.
//
//  Created by Emilio Lugo on 2/28/26.
//

import SwiftUI

struct ProfileView: View {
    @Environment(\.colorScheme) private var colorScheme

    // Placeholder — wire up to your trip data model when ready.
    private let visitedKeys: Set<String> = []

    var body: some View {
        VStack(spacing: 0) {
            TabHeader {
                Text("username")
                    .font(.headline)
            }

            ScrollView {
                WorldMapView(visitedKeys: visitedKeys)
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
            }
        }
        .background(AppTheme.background(for: colorScheme))
        .foregroundStyle(AppTheme.primaryText(for: colorScheme))
    }
}

#Preview {
    ProfileView()
}
