//
//  BottomTabBar.swift
//  vjr.
//
//  Created by Emilio Lugo on 2/28/26.
//

import SwiftUI

struct BottomTabBar: View {
    @Binding var selectedTab: ContentViewModel.Tab
    var onPlus: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(alignment: .bottom, spacing: 0) {
            TabBarButton(icon: "text.aligncenter", label: "Feed", isSelected: selectedTab == .feed) {
                selectedTab = .feed
            }

            TabBarButton(icon: "airplane", label: "Trips", isSelected: selectedTab == .trips) {
                selectedTab = .trips
            }

            // Center plus button
            Button(action: onPlus) {
                ZStack {
                    Circle()
                        .fill(AppTheme.plusBackground(for: colorScheme))
                        .frame(width: 56, height: 56)
                        .shadow(color: .black.opacity(0.2), radius: 6, y: 0)
                    Image(systemName: "plus")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(AppTheme.plusIcon(for: colorScheme))
                }
            }
            .frame(maxWidth: .infinity)

            TabBarButton(icon: "person.2.fill", label: "Friends", isSelected: selectedTab == .friends) {
                selectedTab = .friends
            }

            TabBarButton(icon: "person.fill", label: "Profile", isSelected: selectedTab == .profile) {
                selectedTab = .profile
            }
        }
        .padding(.horizontal, 8)
        .padding(.top, 12)
        .padding(.bottom, 28)
        .background(AppTheme.surface(for: colorScheme))
        .overlay(Divider(), alignment: .top)
    }
}

struct TabBarButton: View {
    let icon: String
    let label: String
    let isSelected: Bool
    let action: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                Text(label)
                    .font(.caption2)
            }
            .foregroundStyle(isSelected ? AppTheme.tabBarActive(for: colorScheme) : AppTheme.tabBarInactive(for: colorScheme))
            .frame(maxWidth: .infinity)
        }
    }
}
