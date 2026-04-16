//
//  ProfileView.swift
//  vjr.
//

import SwiftUI

struct ProfileView: View {
    @State private var vm = TripsViewModel()
    @State private var followersCount = 0
    @State private var followingCount = 0

    @AppStorage("currentUsername") private var currentUsername = ""
    @AppStorage("currentUserId")   private var currentUserId   = ""
    @Environment(\.colorScheme) private var colorScheme

    enum ProfileTab { case map, list }
    @State private var selectedTab: ProfileTab = .map

    var body: some View {
        VStack(spacing: 0) {
            // Header
            TabHeader {
                ZStack {
                    Text(currentUsername)
                        .font(.headline)
                    HStack {
                        Spacer()
                        Menu {
                            Button("Switch user") {
                                AppSession.end()
                            }
                            Button("Log out", role: .destructive) {
                                AppSession.end()
                            }
                        } label: {
                            Image(systemName: "gearshape")
                                .font(.system(size: 18))
                        }
                        .padding(.trailing, 16)
                    }
                }
            }

            // Followers / Following
            HStack(spacing: 40) {
                VStack(spacing: 2) {
                    Text("\(followersCount)")
                        .font(.headline)
                    Text("followers")
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondaryText(for: colorScheme))
                }
                VStack(spacing: 2) {
                    Text("\(followingCount)")
                        .font(.headline)
                    Text("following")
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondaryText(for: colorScheme))
                }
            }
            .padding(.vertical, 12)

            // Segmented tab picker
            Picker("View", selection: $selectedTab) {
                Text("Map").tag(ProfileTab.map)
                Text("List").tag(ProfileTab.list)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.bottom, 10)

            // Tab content
            Group {
                if vm.isLoading {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else {
                    switch selectedTab {
                    case .map:  mapContent
                    case .list: listContent
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(AppTheme.background(for: colorScheme))
        .foregroundStyle(AppTheme.primaryText(for: colorScheme))
        .task {
            async let visited: Void = vm.load(username: currentUsername)
            async let user: Void    = loadUser()
            _ = await (visited, user)
        }
        .onDisappear {
            Task { await vm.save(userId: currentUserId) }
        }
        .alert(
            "Something went wrong",
            isPresented: Binding(
                get: { vm.error != nil },
                set: { if !$0 { vm.error = nil } }
            )
        ) {
            Button("OK") { vm.error = nil }
        } message: {
            Text(vm.error?.localizedDescription ?? "")
        }
    }

    // MARK: - Map tab (view-only)

    private var mapContent: some View {
        VStack(spacing: 0) {
            Spacer()
            WorldMapView(visitedKeys: vm.visitedKeys)
                .padding(.horizontal, 16)
            Spacer()
        }
    }

    // MARK: - List tab (all countries, tappable)

    private var listContent: some View {
        let allCountries = CountryStore.shapes.sorted { $0.name < $1.name }
        return List(allCountries) { shape in
            Button {
                vm.toggle(countryKey: shape.id)
            } label: {
                Text(shape.name)
                    .foregroundStyle(
                        vm.visitedKeys.contains(shape.id)
                            ? AppTheme.primaryText(for: colorScheme)
                            : AppTheme.secondaryText(for: colorScheme)
                    )
            }
            .listRowBackground(AppTheme.background(for: colorScheme))
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    // MARK: - Data

    private func loadUser() async {
        guard let user: User = try? await APIClient.shared.fetch("api/user/\(currentUsername)") else { return }
        followersCount = user.followers?.count ?? 0
        followingCount = user.following?.count ?? 0
    }
}

#Preview {
    ProfileView()
}
