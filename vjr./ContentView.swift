//
//  ContentView.swift
//  vjr.
//
//  Created by Emilio Lugo on 2/28/26.
//

import SwiftUI

struct ContentView: View {
    @State private var vm = ContentViewModel()
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        @Bindable var viewModel = vm
        ZStack(alignment: .bottom) {
            TabView(selection: $viewModel.selectedTab) {
                FeedView()
                    .tag(ContentViewModel.Tab.feed)
                    .toolbar(.hidden, for: .tabBar)
                TripsView()
                    .tag(ContentViewModel.Tab.trips)
                    .toolbar(.hidden, for: .tabBar)
                FriendsView()
                    .tag(ContentViewModel.Tab.friends)
                    .toolbar(.hidden, for: .tabBar)
                ProfileView()
                    .tag(ContentViewModel.Tab.profile)
                    .toolbar(.hidden, for: .tabBar)
            }

            BottomTabBar(selectedTab: $viewModel.selectedTab, onPlus: { vm.showNewTrip = true })
        }
        .background(AppTheme.background(for: colorScheme))
        .tint(AppTheme.tabBarActive(for: colorScheme))
        .ignoresSafeArea(edges: .bottom)
        .sheet(isPresented: $viewModel.showNewTrip) {
            Text("New Trip")
                .foregroundStyle(AppTheme.primaryText(for: colorScheme))
                .presentationDetents([.medium])
        }
    }
}

#Preview {
    ContentView()
}
