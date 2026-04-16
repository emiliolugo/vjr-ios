//
//  TripLocalStore.swift
//  vjr.
//
//  JSON persistence in Application Support, keyed by username.

import Foundation
import Observation

@Observable
@MainActor
final class TripLocalStore {
    private(set) var trips: [Trip] = []
    var loadError: AppError?

    private var username: String = ""

    private static let fileNamePrefix = "trips_"

    func setContext(username: String) {
        self.username = username
        load()
    }

    func add(_ trip: Trip) {
        trips.insert(trip, at: 0)
        save()
    }

    private func directory() throws -> URL {
        let base = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let dir = base.appendingPathComponent("vjr", isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    private func fileURL() throws -> URL {
        let safe = username.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? "user"
        return try directory().appendingPathComponent("\(Self.fileNamePrefix)\(safe).json")
    }

    func load() {
        loadError = nil
        guard !username.isEmpty else {
            trips = []
            return
        }
        do {
            let url = try fileURL()
            guard FileManager.default.fileExists(atPath: url.path) else {
                trips = []
                return
            }
            let data = try Data(contentsOf: url)
            let decoded = try JSONDecoder().decode([Trip].self, from: data)
            trips = decoded.sorted { $0.createdAt > $1.createdAt }
        } catch {
            loadError = AppError.network(error.localizedDescription)
            trips = []
        }
    }

    private func save() {
        guard !username.isEmpty else { return }
        do {
            let data = try JSONEncoder().encode(trips)
            let url = try fileURL()
            try data.write(to: url, options: .atomic)
        } catch {
            loadError = AppError.network(error.localizedDescription)
        }
    }
}
