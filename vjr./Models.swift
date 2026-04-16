//
//  Models.swift
//  vjr.
//
//  Codable structs matching the JSON responses from the Vapor server (api/).
//  Keep in sync with api/Sources/api/Models/ and api/Sources/api/routes.swift.
//
//  ID field guide:
//    User.id         — Prisma cuid. Used in follow/request API bodies.
//    User.userId     — Clerk external ID. Used in visited-countries queries.
//    User.username   — Display name. Used in follow GET, user lookup, POST bodies.

import Foundation

struct User: Codable, Identifiable, Hashable {
    let id: String
    let userId: String
    let username: String
    let email: String
    let firstName: String
    let lastName: String?
    let isPrivate: Bool
    let followers: [Follow]?
    let following: [Follow]?
}

extension User: Equatable {
    static func == (lhs: User, rhs: User) -> Bool {
        return lhs.id == rhs.id && lhs.userId == rhs.userId && lhs.username == rhs.username
    }
}

extension User {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(userId)
        hasher.combine(username)
        hasher.combine(email)
        hasher.combine(firstName)
        hasher.combine(lastName)
        hasher.combine(isPrivate)
    }
}

struct VisitedCountry: Codable, Identifiable {
    let id: Int
    let userId: String      // Clerk userId
    let country: String     // Full country name matching countries.json key (e.g. "United States")
    let visitedAt: String   // ISO 8601 date string
}

struct Follow: Codable, Identifiable {
    let id: String
    let followerId: String  // User.id of the follower
    let followingId: String // User.id of the person being followed
}

struct FollowRequest: Codable, Identifiable {
    let id: String
    let requesterId: String // User.id of the person requesting
    let requesteeId: String // User.id of the person being requested
}

// Lightweight model used to build the social feed (constructed client-side,
// not returned directly by any API endpoint).
struct FeedItem: Identifiable {
    let id: String          // composite: "\(username)-\(countryKey)"
    let username: String
    let countryKey: String
    let countryName: String // resolved from CountryStore.shared
}

// MARK: - API request bodies

struct VisitedUpdateBody: Codable {
    let userId: String       // Clerk userId (currentUserId)
    let country: [String]    // full country names
    let visited: [Bool]      // parallel — true = add, false = remove
}

struct FollowToggleBody: Codable {
    let personBeingFollowed: String  // username of target
    let personFollowing: String      // username of current user
    let follow: Bool
}

struct SendFollowRequestBody: Codable {
    let requester: String   // username of current user
    let requestee: String   // username of target
}

struct HandleFollowBody: Codable {
    let followerId: String   // User.id (prisma cuid) of the requester
    let followeeId: String   // User.id (prisma cuid) of the current user
    let isAccepted: Bool
}

// MARK: - API response envelopes

struct VisitedResponse: Codable {
    let visited: [String]
}

struct ActionResponse: Codable {
    let success: Bool
    let action: String
}
