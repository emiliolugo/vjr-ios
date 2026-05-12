//
//  DestinationRecommendation.swift
//  vjr.
//
//  Social-first country recommendations.

import Foundation
import Observation

struct DestinationRecommendation: Identifiable, Hashable {
    let countryName: String
    let mutualTravelers: [String]
    let otherTravelers: [String]
    let nearestRecentCountry: String?
    let distanceFromRecentKM: Double?

    var id: String { countryName }

    var socialCount: Int {
        mutualTravelers.count + otherTravelers.count
    }

    var visibleTravelers: [String] {
        Array((mutualTravelers + otherTravelers).prefix(4))
    }

    var socialSummary: String {
        let count = socialCount
        guard count > 0 else { return "No traveler signal yet" }

        let label = count == 1 ? "traveler" : "travelers"
        if mutualTravelers.isEmpty {
            return "\(count) followed \(label) traveled there"
        }

        let mutualLabel = mutualTravelers.count == 1 ? "mutual" : "mutuals"
        return "\(mutualTravelers.count) \(mutualLabel) traveled there"
    }

    var geographySummary: String {
        guard
            let nearestRecentCountry,
            let distanceFromRecentKM
        else {
            return "Add more trips to improve nearby matching"
        }

        let rounded = Int((distanceFromRecentKM / 100).rounded() * 100)
        return "Near your recent \(nearestRecentCountry) trip - about \(rounded) km away"
    }
}

@Observable
@MainActor
final class DestinationRecommendationsViewModel {
    var recommendations: [DestinationRecommendation] = []
    var isLoading = false
    var error: AppError?

    private var lastLoadedKey = ""

    func load(username: String, prismaId: String, recentTrips: [Trip], force: Bool = false) async {
        let recentKey = recentTrips.prefix(4).map { $0.id.uuidString + "\($0.updatedAt.timeIntervalSince1970)" }.joined()
        let loadKey = "\(username)|\(prismaId)|\(recentKey)"
        guard force || loadKey != lastLoadedKey else { return }
        lastLoadedKey = loadKey

        guard !username.isEmpty, !prismaId.isEmpty else {
            recommendations = []
            return
        }

        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            async let followers: [User] = APIClient.shared.fetch(
                "api/follow",
                query: ["username": username, "following": "false"]
            )
            async let following: [User] = APIClient.shared.fetch(
                "api/follow",
                query: ["username": username, "following": "true"]
            )

            let socialGraph = try await SocialGraph(followers: followers, following: following)
            recommendations = try await buildRecommendations(
                socialGraph: socialGraph,
                recentTrips: recentTrips
            )
        } catch {
            self.error = AppError.from(error)
            recommendations = []
        }
    }

    private func buildRecommendations(
        socialGraph: SocialGraph,
        recentTrips: [Trip]
    ) async throws -> [DestinationRecommendation] {
        let travelers = socialGraph.rankedTravelers
        guard !travelers.isEmpty else { return [] }

        var countrySignals: [String: TravelerSignal] = [:]

        for traveler in travelers {
            let response: VisitedResponse = try await APIClient.shared.fetch(
                "api/visited",
                query: ["username": traveler.user.username]
            )
            for country in Set(response.visited) {
                countrySignals[country, default: TravelerSignal()].add(traveler)
            }
        }

        let visitedByMe = Set(recentTrips.flatMap(\.countryNames))
        let recentAnchors = recentTrips
            .sorted { $0.createdAt > $1.createdAt }
            .flatMap(\.countryNames)

        return countrySignals
            .filter { country, signal in
                !visitedByMe.contains(country) && signal.count > 0
            }
            .map { country, signal in
                let nearest = nearestAnchor(to: country, recentCountries: recentAnchors)
                return DestinationRecommendation(
                    countryName: country,
                    mutualTravelers: signal.mutualTravelers.sorted(),
                    otherTravelers: signal.otherTravelers.sorted(),
                    nearestRecentCountry: nearest?.country,
                    distanceFromRecentKM: nearest?.distanceKM
                )
            }
            .sorted { lhs, rhs in
                recommendationScore(lhs) > recommendationScore(rhs)
            }
    }

    private func recommendationScore(_ recommendation: DestinationRecommendation) -> Double {
        let social = Double(recommendation.mutualTravelers.count * 100 + recommendation.otherTravelers.count * 30)
        let nearby = recommendation.distanceFromRecentKM.map { max(0, 60 - ($0 / 250)) } ?? 0
        return social + nearby
    }

    private func nearestAnchor(to country: String, recentCountries: [String]) -> (country: String, distanceKM: Double)? {
        guard let target = CountryCoordinates.lookup(country) else { return nil }

        return recentCountries
            .compactMap { recentCountry -> (country: String, distanceKM: Double)? in
                guard let anchor = CountryCoordinates.lookup(recentCountry) else { return nil }
                return (recentCountry, target.distance(to: anchor))
            }
            .min { $0.distanceKM < $1.distanceKM }
    }
}

private struct SocialGraph {
    let mutuals: [User]
    let followingOnly: [User]

    init(followers: [User], following: [User]) {
        let followerIds = Set(followers.map(\.id))
        mutuals = following.filter { followerIds.contains($0.id) }
        followingOnly = following.filter { !followerIds.contains($0.id) }
    }

    var rankedTravelers: [RankedTraveler] {
        mutuals.map { RankedTraveler(user: $0, isMutual: true) }
            + followingOnly.map { RankedTraveler(user: $0, isMutual: false) }
    }
}

private struct RankedTraveler {
    let user: User
    let isMutual: Bool
}

private struct TravelerSignal {
    var mutualTravelers: Set<String> = []
    var otherTravelers: Set<String> = []

    var count: Int {
        mutualTravelers.count + otherTravelers.count
    }

    mutating func add(_ traveler: RankedTraveler) {
        if traveler.isMutual {
            mutualTravelers.insert(traveler.user.username)
        } else {
            otherTravelers.insert(traveler.user.username)
        }
    }
}

private struct CountryCoordinate {
    let latitude: Double
    let longitude: Double

    func distance(to other: CountryCoordinate) -> Double {
        let radius = 6371.0
        let dLat = (other.latitude - latitude).degreesToRadians
        let dLon = (other.longitude - longitude).degreesToRadians
        let lat1 = latitude.degreesToRadians
        let lat2 = other.latitude.degreesToRadians

        let a = sin(dLat / 2) * sin(dLat / 2)
            + sin(dLon / 2) * sin(dLon / 2) * cos(lat1) * cos(lat2)
        return radius * 2 * atan2(sqrt(a), sqrt(1 - a))
    }
}

private enum CountryCoordinates {
    private static let coordinates: [String: CountryCoordinate] = [
        "Argentina": .init(latitude: -34.6037, longitude: -58.3816),
        "Australia": .init(latitude: -35.2809, longitude: 149.1300),
        "Austria": .init(latitude: 48.2082, longitude: 16.3738),
        "Brazil": .init(latitude: -15.7939, longitude: -47.8828),
        "Canada": .init(latitude: 45.4215, longitude: -75.6972),
        "Chile": .init(latitude: -33.4489, longitude: -70.6693),
        "China": .init(latitude: 39.9042, longitude: 116.4074),
        "Colombia": .init(latitude: 4.7110, longitude: -74.0721),
        "Costa Rica": .init(latitude: 9.9281, longitude: -84.0907),
        "Croatia": .init(latitude: 45.8150, longitude: 15.9819),
        "Czech Republic": .init(latitude: 50.0755, longitude: 14.4378),
        "Denmark": .init(latitude: 55.6761, longitude: 12.5683),
        "Egypt": .init(latitude: 30.0444, longitude: 31.2357),
        "France": .init(latitude: 48.8566, longitude: 2.3522),
        "Germany": .init(latitude: 52.5200, longitude: 13.4050),
        "Greece": .init(latitude: 37.9838, longitude: 23.7275),
        "Iceland": .init(latitude: 64.1466, longitude: -21.9426),
        "India": .init(latitude: 28.6139, longitude: 77.2090),
        "Indonesia": .init(latitude: -6.2088, longitude: 106.8456),
        "Ireland": .init(latitude: 53.3498, longitude: -6.2603),
        "Italy": .init(latitude: 41.9028, longitude: 12.4964),
        "Japan": .init(latitude: 35.6762, longitude: 139.6503),
        "Mexico": .init(latitude: 19.4326, longitude: -99.1332),
        "Morocco": .init(latitude: 34.0209, longitude: -6.8416),
        "Netherlands": .init(latitude: 52.3676, longitude: 4.9041),
        "New Zealand": .init(latitude: -41.2865, longitude: 174.7762),
        "Norway": .init(latitude: 59.9139, longitude: 10.7522),
        "Peru": .init(latitude: -12.0464, longitude: -77.0428),
        "Portugal": .init(latitude: 38.7223, longitude: -9.1393),
        "Singapore": .init(latitude: 1.3521, longitude: 103.8198),
        "South Africa": .init(latitude: -33.9249, longitude: 18.4241),
        "South Korea": .init(latitude: 37.5665, longitude: 126.9780),
        "Spain": .init(latitude: 40.4168, longitude: -3.7038),
        "Sweden": .init(latitude: 59.3293, longitude: 18.0686),
        "Switzerland": .init(latitude: 46.9480, longitude: 7.4474),
        "Thailand": .init(latitude: 13.7563, longitude: 100.5018),
        "Turkey": .init(latitude: 41.0082, longitude: 28.9784),
        "United Arab Emirates": .init(latitude: 25.2048, longitude: 55.2708),
        "United Kingdom": .init(latitude: 51.5072, longitude: -0.1276),
        "United States": .init(latitude: 38.9072, longitude: -77.0369),
        "Vietnam": .init(latitude: 21.0278, longitude: 105.8342)
    ]

    static func lookup(_ country: String) -> CountryCoordinate? {
        coordinates[country]
    }
}

private extension Double {
    var degreesToRadians: Double {
        self * .pi / 180
    }
}
