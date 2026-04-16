//
//  UserProfileView.swift
//  vjr.
//
//  Shows another user's profile: their world map, follower/following counts,
//  and the appropriate follow/unfollow/request button based on relationship + privacy.

import SwiftUI

struct UserProfileView: View {
    let user: User
    @Bindable var friendsVM: FriendsViewModel

    @State private var tripsVM = TripsViewModel()
    @State private var followersCount = 0
    @State private var followingCount = 0
    @State private var showUnfollowConfirm = false

    @AppStorage("currentUsername") private var currentUsername = ""
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 0) {
            // Followers / Following counts
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

            // Follow / Unfollow / Request button
            followButton
                .padding(.horizontal, 32)
                .padding(.bottom, 12)

            // World map
            Spacer()
            WorldMapView(visitedKeys: tripsVM.visitedKeys)
                .padding(.horizontal, 16)
            Spacer()
        }
        .navigationTitle(user.username)
        .navigationBarTitleDisplayMode(.inline)
        .background(AppTheme.background(for: colorScheme))
        .foregroundStyle(AppTheme.primaryText(for: colorScheme))
        .task {
            async let map: Void   = tripsVM.load(username: user.username)
            async let detail: Void = loadUserDetail()
            _ = await (map, detail)
        }
        .confirmationDialog(
            "Unfollow \(user.username)?",
            isPresented: $showUnfollowConfirm,
            titleVisibility: .visible
        ) {
            Button("Unfollow", role: .destructive) {
                Task { await friendsVM.unfollow(target: user, currentUsername: currentUsername) }
            }
        } message: {
            Text("You'll need to send a new request to follow them again.")
        }
        .alert(
            "Something went wrong",
            isPresented: Binding(
                get: { tripsVM.error != nil },
                set: { if !$0 { tripsVM.error = nil } }
            )
        ) {
            Button("OK") { tripsVM.error = nil }
        } message: {
            Text(tripsVM.error?.localizedDescription ?? "")
        }
        .alert(
            "Something went wrong",
            isPresented: Binding(
                get: { friendsVM.error != nil },
                set: { if !$0 { friendsVM.error = nil } }
            )
        ) {
            Button("OK") { friendsVM.error = nil }
        } message: {
            Text(friendsVM.error?.localizedDescription ?? "")
        }
    }

    // MARK: - Follow button

    @ViewBuilder
    private var followButton: some View {
        if friendsVM.isFollowing(user) {
            Button {
                if user.isPrivate {
                    showUnfollowConfirm = true
                } else {
                    Task { await friendsVM.unfollow(target: user, currentUsername: currentUsername) }
                }
            } label: {
                Text("Unfollow")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(AppTheme.surface(for: colorScheme))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(AppTheme.secondaryText(for: colorScheme).opacity(0.3), lineWidth: 1)
                    )
            }
        } else if user.isPrivate {
            if friendsVM.hasSentRequest(to: user) {
                Text("Requested")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(AppTheme.surface(for: colorScheme))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(AppTheme.secondaryText(for: colorScheme).opacity(0.3), lineWidth: 1)
                    )
                    .foregroundStyle(AppTheme.secondaryText(for: colorScheme))
            } else {
                Button {
                    Task { await friendsVM.sendRequest(to: user, from: currentUsername) }
                } label: {
                    Text("Request")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(AppTheme.surface(for: colorScheme))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(AppTheme.secondaryText(for: colorScheme).opacity(0.3), lineWidth: 1)
                        )
                }
            }
        } else {
            Button {
                Task { await friendsVM.follow(target: user, currentUsername: currentUsername) }
            } label: {
                Text("Follow")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(AppTheme.surface(for: colorScheme))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(AppTheme.secondaryText(for: colorScheme).opacity(0.3), lineWidth: 1)
                    )
            }
        }
    }

    // MARK: - Data

    private func loadUserDetail() async {
        guard let detail: User = try? await APIClient.shared.fetch("api/user/\(user.username)") else { return }
        followersCount = detail.followers?.count ?? 0
        followingCount = detail.following?.count ?? 0
    }
}
