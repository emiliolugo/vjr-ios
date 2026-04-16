//
//  TripModels.swift
//  vjr.
//
//  Local-first trip domain types. See docs/TRIPS.md.

import Foundation

// MARK: - Placeholder cover

enum TripCoverPlaceholder: String, Codable, CaseIterable, Identifiable {
    case moss
    case slate
    case rust
    case ocean

    var id: String { rawValue }
}

// MARK: - Skeleton for future hotel/airline ratings (no logic in v1)

struct TripSegmentRatingsPlaceholder: Codable, Equatable, Sendable {}

// MARK: - Trip

struct Trip: Codable, Identifiable, Equatable, Hashable {
    var id: UUID
    /// Full country names — same strings as `countries.json` / visited API.
    var countryNames: [String]
    var startDate: Date
    var endDate: Date
    var caption: String
    var activities: [String]
    var hotels: [String]
    var airlines: [String]
    var hotelRatingPlaceholder: TripSegmentRatingsPlaceholder?
    var airlineRatingPlaceholder: TripSegmentRatingsPlaceholder?
    /// One decimal semantic (stored as e.g. 8.3).
    var tripRating: Double
    var coverPlaceholder: TripCoverPlaceholder
    var createdAt: Date
    var updatedAt: Date

    /// v1 list row; future: optional `displayTitle` overrides.
    var listTitle: String {
        guard let first = countryNames.first else { return "Trip" }
        if countryNames.count == 1 { return first }
        return "\(first) + \(countryNames.count - 1) more"
    }
}

extension Trip {
    func hash(into hasher: inout Hasher) {
        hasher.combine(countryNames)
        hasher.combine(startDate)
        hasher.combine(endDate)
        hasher.combine(caption)
        hasher.combine(hotels)
        hasher.combine(tripRating)
        hasher.combine(airlines)
        hasher.combine(caption)
        hasher.combine(listTitle)
        hasher.combine(createdAt)
        hasher.combine(updatedAt)
    }
}
// MARK: - Draft (in-memory until rating completes)

struct TripDraft {
    var countryNames: [String] = []
    var startDate: Date = .now
    var endDate: Date = .now
    var caption: String = ""
    var activities: [String] = ["", "", "", "", ""]
    var hotelLine: String = ""
    var airlineLine: String = ""
    var coverPlaceholder: TripCoverPlaceholder = .moss

    func normalizedActivities() -> [String] {
        activities
            .map { String($0.prefix(80)).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    func hotelsArray() -> [String] {
        let t = hotelLine.trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? [] : [t]
    }

    func airlinesArray() -> [String] {
        let t = airlineLine.trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? [] : [t]
    }

    func makeTrip(id: UUID, tripRating: Double, now: Date) -> Trip {
        Trip(
            id: id,
            countryNames: countryNames,
            startDate: startDate,
            endDate: endDate,
            caption: caption,
            activities: normalizedActivities(),
            hotels: hotelsArray(),
            airlines: airlinesArray(),
            hotelRatingPlaceholder: nil,
            airlineRatingPlaceholder: nil,
            tripRating: (tripRating * 10).rounded() / 10,
            coverPlaceholder: coverPlaceholder,
            createdAt: now,
            updatedAt: now
        )
    }
}
