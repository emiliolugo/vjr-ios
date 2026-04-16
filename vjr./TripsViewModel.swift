//
//  TripsViewModel.swift
//  vjr.
//
//  Fetches and holds the current user's visited countries.
//  Toggle changes are batched and sent on tab exit via save(userId:).

import Observation

@Observable
final class TripsViewModel {
    var visitedKeys: Set<String> = []
    var isLoading = false
    var error: AppError? = nil

    private var originalKeys: Set<String> = []  // snapshot at load time — used to compute delta

    func load(username: String) async {
        isLoading = true
        error = nil
        defer { isLoading = false }
        do {
            let resp: VisitedResponse = try await APIClient.shared.fetch(
                "api/visited", query: ["username": username]
            )
            visitedKeys  = Set(resp.visited)
            originalKeys = visitedKeys
        } catch {
            self.error = AppError.from(error)
        }
    }

    /// Toggles a country locally. No network call — changes are batched until save(userId:).
    func toggle(countryKey: String) {
        if visitedKeys.contains(countryKey) {
            visitedKeys.remove(countryKey)
        } else {
            visitedKeys.insert(countryKey)
        }
    }

    /// Computes the delta vs the last loaded state and POSTs only what changed.
    /// Called on tab exit (onDisappear). No-ops if nothing changed.
    func save(userId: String) async {
        let added   = visitedKeys.subtracting(originalKeys)
        let removed = originalKeys.subtracting(visitedKeys)

        let countries = Array(added) + Array(removed)
        let flags     = Array(repeating: true,  count: added.count)
                      + Array(repeating: false, count: removed.count)

        guard !countries.isEmpty else { return }

        do {
            let body = VisitedUpdateBody(userId: userId, country: countries, visited: flags)
            let resp: VisitedResponse = try await APIClient.shared.post("api/visited", body: body)
            visitedKeys  = Set(resp.visited)
            originalKeys = visitedKeys
        } catch {
            self.error = AppError.from(error)
        }
    }
}
