//
//  vjr_App.swift
//  vjr.
//

import SwiftUI

@main
struct VjrApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}

// MARK: - Root

/// Shows LoginView when no session exists, otherwise shows the main tab interface.
struct RootView: View {
    @AppStorage("currentUsername") private var currentUsername = ""

    var body: some View {
        if currentUsername.isEmpty {
            LoginView()
        } else {
            MainTabView()
        }
    }
}

// MARK: - Main tab container

struct MainTabView: View {
    @State private var vm = ContentViewModel()
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        @Bindable var vm = vm
        VStack(spacing: 0) {
            Group {
                switch vm.selectedTab {
                case .feed:     FeedView()
                case .trips:    TripsView()
                case .friends:  FriendsView()
                case .profile:  ProfileView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            BottomTabBar(selectedTab: $vm.selectedTab, onPlus: { vm.showNewTrip = true })
        }
        .ignoresSafeArea(edges: .bottom)
        .background(AppTheme.background(for: colorScheme))
    }
}
