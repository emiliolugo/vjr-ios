//
//  FriendsViewModel.swift
//  vjr.
//
//  Loads followers, following, and follow requests for the current user.
//  Provides all follow/unfollow/request/handle actions used by FriendsView
//  and UserProfileView.

import Observation

@Observable
final class FriendsViewModel {
    var followers: [User]        = []
    var following: [User]        = []
    var incomingRequests: [User] = []
    var outgoingRequests: [User] = []   // silent — not shown in UI, used for "Requested" button state
    var isLoading = false
    var error: AppError? = nil

    // MARK: - Load

    func loadAll(username: String, prismaId: String) async {
        isLoading = true
        error = nil
        defer { isLoading = false }
        do {
            async let fetchedFollowers: [User]  = APIClient.shared.fetch(
                "api/follow", query: ["username": username, "following": "false"]
            )
            async let fetchedFollowing: [User]  = APIClient.shared.fetch(
                "api/follow", query: ["username": username, "following": "true"]
            )
            async let fetchedIncoming: [User]   = APIClient.shared.fetch(
                "api/requestFollow", query: ["id": prismaId, "isOutgoing": "false"]
            )
            async let fetchedOutgoing: [User]   = APIClient.shared.fetch(
                "api/requestFollow", query: ["id": prismaId, "isOutgoing": "true"]
            )
            (followers, following, incomingRequests, outgoingRequests) =
                try await (fetchedFollowers, fetchedFollowing, fetchedIncoming, fetchedOutgoing)
        } catch {
            self.error = AppError.from(error)
        }
    }

    // MARK: - Relationship helpers

    func isFollowing(_ user: User) -> Bool {
        following.contains { $0.id == user.id }
    }

    func hasSentRequest(to user: User) -> Bool {
        outgoingRequests.contains { $0.id == user.id }
    }

    // MARK: - Actions

    func follow(target: User, currentUsername: String) async {
        do {
            let body = FollowToggleBody(
                personBeingFollowed: target.username,
                personFollowing: currentUsername,
                follow: true
            )
            let _: ActionResponse = try await APIClient.shared.post("api/follow", body: body)
            if !following.contains(where: { $0.id == target.id }) {
                following.append(target)
            }
        } catch {
            self.error = AppError.from(error)
        }
    }

    func unfollow(target: User, currentUsername: String) async {
        do {
            let body = FollowToggleBody(
                personBeingFollowed: target.username,
                personFollowing: currentUsername,
                follow: false
            )
            let _: ActionResponse = try await APIClient.shared.post("api/follow", body: body)
            following.removeAll { $0.id == target.id }
        } catch {
            self.error = AppError.from(error)
        }
    }

    func sendRequest(to target: User, from currentUsername: String) async {
        do {
            let body = SendFollowRequestBody(requester: currentUsername, requestee: target.username)
            let _: ActionResponse = try await APIClient.shared.post("api/requestFollow", body: body)
            if !outgoingRequests.contains(where: { $0.id == target.id }) {
                outgoingRequests.append(target)
            }
        } catch {
            self.error = AppError.from(error)
        }
    }

    func handleRequest(requesterPrismaId: String, myPrismaId: String, accept: Bool) async {
        do {
            let body = HandleFollowBody(
                followerId: requesterPrismaId,
                followeeId: myPrismaId,
                isAccepted: accept
            )
            let _: ActionResponse = try await APIClient.shared.post("api/handleFollow", body: body)
            incomingRequests.removeAll { $0.id == requesterPrismaId }
            if accept {
                // Reload following so the new follower appears correctly
                if let newFollower = followers.first(where: { $0.id == requesterPrismaId }) {
                    if !following.contains(where: { $0.id == newFollower.id }) {
                        following.append(newFollower)
                    }
                }
            }
        } catch {
            self.error = AppError.from(error)
        }
    }
}
