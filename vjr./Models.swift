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

struct User: Codable, Identifiable {
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

// MARK: - API response envelopes

struct VisitedResponse: Codable {
    let visited: [String]
}

struct ActionResponse: Codable {
    let success: Bool
    let action: String
}
