//
//  FriendsView.swift
//  vjr.
//

import SwiftUI

struct FriendsView: View {
    @State private var vm = FriendsViewModel()

    @AppStorage("currentUsername")     private var currentUsername     = ""
    @AppStorage("currentUserPrismaId") private var currentUserPrismaId = ""
    @Environment(\.colorScheme) private var colorScheme

    enum FriendsTab { case followers, following, requests }
    @State private var selectedTab: FriendsTab = .followers

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                TabHeader {
                    Text("Friends")
                        .font(.headline)
                }

                // Segmented picker
                Picker("Section", selection: $selectedTab) {
                    Text("Followers").tag(FriendsTab.followers)
                    Text("Following").tag(FriendsTab.following)
                    Text("Requests").tag(FriendsTab.requests)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)

                // Content
                Group {
                    if vm.isLoading {
                        Spacer()
                        ProgressView()
                        Spacer()
                    } else {
                        switch selectedTab {
                        case .followers: followersContent
                        case .following: followingContent
                        case .requests:  requestsContent
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .background(AppTheme.background(for: colorScheme))
            .foregroundStyle(AppTheme.primaryText(for: colorScheme))
            .navigationDestination(for: User.self) { user in
                UserProfileView(user: user, friendsVM: vm)
            }
            .task {
                await vm.loadAll(username: currentUsername, prismaId: currentUserPrismaId)
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
    }

    // MARK: - Followers tab

    private var followersContent: some View {
        Group {
            if vm.followers.isEmpty {
                emptyState("No followers yet.")
            } else {
                List(vm.followers) { user in
                    NavigationLink(value: user) {
                        Text(user.username)
                    }
                    .listRowBackground(AppTheme.background(for: colorScheme))
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
    }

    // MARK: - Following tab

    private var followingContent: some View {
        Group {
            if vm.following.isEmpty {
                emptyState("Not following anyone yet.")
            } else {
                List(vm.following) { user in
                    HStack {
                        NavigationLink(value: user) {
                            Text(user.username)
                        }
                        Spacer()
                        UnfollowButton(user: user, vm: vm)
                    }
                    .listRowBackground(AppTheme.background(for: colorScheme))
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
    }

    // MARK: - Requests tab

    private var requestsContent: some View {
        Group {
            if vm.incomingRequests.isEmpty {
                emptyState("No pending requests.")
            } else {
                List(vm.incomingRequests) { user in
                    HStack {
                        NavigationLink(value: user) {
                            Text(user.username)
                        }
                        Spacer()
                        Button("Accept") {
                            Task {
                                await vm.handleRequest(
                                    requesterPrismaId: user.id,
                                    myPrismaId: currentUserPrismaId,
                                    accept: true
                                )
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)

                        Button("Decline", role: .destructive) {
                            Task {
                                await vm.handleRequest(
                                    requesterPrismaId: user.id,
                                    myPrismaId: currentUserPrismaId,
                                    accept: false
                                )
                            }
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                    .listRowBackground(AppTheme.background(for: colorScheme))
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
    }

    // MARK: - Helpers

    private func emptyState(_ message: String) -> some View {
        VStack {
            Spacer()
            Text(message)
                .foregroundStyle(AppTheme.secondaryText(for: colorScheme))
            Spacer()
        }
    }
}

// MARK: - Unfollow button (extracted to own view for confirmationDialog scoping)

private struct UnfollowButton: View {
    let user: User
    @Bindable var vm: FriendsViewModel

    @AppStorage("currentUsername") private var currentUsername = ""
    @State private var showConfirm = false

    var body: some View {
        Button("Unfollow") {
            if user.isPrivate {
                showConfirm = true
            } else {
                Task { await vm.unfollow(target: user, currentUsername: currentUsername) }
            }
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
        .confirmationDialog(
            "Unfollow \(user.username)?",
            isPresented: $showConfirm,
            titleVisibility: .visible
        ) {
            Button("Unfollow", role: .destructive) {
                Task { await vm.unfollow(target: user, currentUsername: currentUsername) }
            }
        } message: {
            Text("You'll need to send a new request to follow them again.")
        }
    }
}

#Preview {
    FriendsView()
}
