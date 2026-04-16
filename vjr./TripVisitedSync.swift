//
//  TripVisitedSync.swift
//  vjr.
//
//  POST newly visited countries after a trip is saved. See docs/TRIPS.md §4.

import Foundation

enum TripVisitedSync {
    /// Adds any trip countries not already returned by `GET /api/visited`.
    static func addNewCountries(_ names: [String], username: String, userId: String) async throws {
        guard !userId.isEmpty else { return }
        let resp: VisitedResponse = try await APIClient.shared.fetch(
            "api/visited",
            query: ["username": username]
        )
        let existing = Set(resp.visited)
        let toAdd = names.filter { !existing.contains($0) }
        guard !toAdd.isEmpty else { return }
        let body = VisitedUpdateBody(
            userId: userId,
            country: toAdd,
            visited: Array(repeating: true, count: toAdd.count)
        )
        _ = try await APIClient.shared.post("api/visited", body: body) as VisitedResponse
    }
}
