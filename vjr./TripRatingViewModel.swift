//
//  TripRatingViewModel.swift
//  vjr.
//
//  Belli-style bucket + strict binary search on a 0.1 grid. See docs/TRIPS.md §3.

import Foundation
import Observation

@Observable
final class TripRatingViewModel {
    enum Phase {
        case bucket
        case question
        case finished(score10: Int)
    }

    private(set) var phase: Phase = .bucket
    /// Question shown for `.question` phase.
    private(set) var prompt: String = ""
    private(set) var referenceTrip: Trip?
    /// `true` when the score was set to the bucket median with no comparison steps (first trip in that bucket).
    private(set) var usedBucketMedianShortcut = false

    private var bucket: RatingBucket?
    /// Admissible scores as tenths (7.0 → 70 … 10.0 → 100 for liked).
    private var admissible: [Int] = []
    private var pivotScore10: Int?
    private let priorTrips: [Trip]

    init(priorTrips: [Trip]) {
        self.priorTrips = priorTrips
    }

    // MARK: - Bucket pick

    func chooseLiked() {
        start(with: .liked)
    }

    func chooseOkay() {
        start(with: .okay)
    }

    func chooseDidntEnjoy() {
        start(with: .didnt)
    }

    private func start(with b: RatingBucket) {
        bucket = b
        admissible = Array(b.scoreRange)
        referenceTrip = nil

        // First trip in this bucket: skip comparisons; score = median of the bucket grid (docs/TRIPS.md).
        let priorInBucket = priorTrips.filter { b.scoreRange.contains(Self.score10($0.tripRating)) }
        if priorInBucket.isEmpty {
            let grid = Array(b.scoreRange)
            let median = grid[grid.count / 2]
            usedBucketMedianShortcut = true
            phase = .finished(score10: median)
            prompt = ""
            return
        }

        usedBucketMedianShortcut = false
        advance()
    }

    // MARK: - Answers

    func answerMoreEnjoyable() {
        apply(strictlyGreater: true)
    }

    func answerLessEnjoyable() {
        apply(strictlyGreater: false)
    }

    // MARK: - Result

    var finishedScore10: Int? {
        if case .finished(let s) = phase { return s }
        return nil
    }

    // MARK: - Internals

    private func apply(strictlyGreater: Bool) {
        guard case .question = phase else { return }

        if let trip = referenceTrip {
            let r = Self.score10(trip.tripRating)
            admissible = strictlyGreater ? admissible.filter { $0 > r } : admissible.filter { $0 < r }
        } else if let p = pivotScore10 {
            admissible = strictlyGreater ? admissible.filter { $0 > p } : admissible.filter { $0 < p }
        }

        recoverIfEmpty()
        finishOrAdvance()
    }

    private func finishOrAdvance() {
        if admissible.count == 1, let only = admissible.first {
            phase = .finished(score10: only)
            prompt = ""
            referenceTrip = nil
            return
        }
        advance()
    }

    private func advance() {
        guard admissible.count > 1 else {
            if let only = admissible.first {
                phase = .finished(score10: only)
            }
            return
        }

        let tripsHere = priorTrips.filter { admissible.contains(Self.score10($0.tripRating)) }
            .sorted { $0.tripRating < $1.tripRating }

        if let med = medianTrip(tripsHere) {
            referenceTrip = med
            pivotScore10 = nil
            let label = med.listTitle
            let score = Self.display(med.tripRating)
            prompt = "Compared to your trip \"\(label)\" (you rated it \(score)), was this new trip more enjoyable, or less enjoyable?"
        } else {
            referenceTrip = nil
            let mid = admissible[admissible.count / 2]
            pivotScore10 = mid
            prompt = "Was this trip more enjoyable or less enjoyable than a trip you’d rate around \(Self.displayScore10(mid))?"
        }

        phase = .question
    }

    private func recoverIfEmpty() {
        guard admissible.isEmpty, let b = bucket else { return }
        // Inconsistent answers — fall back to middle of full bucket.
        admissible = [b.scoreRange.lowerBound + (b.scoreRange.upperBound - b.scoreRange.lowerBound) / 2]
    }

    private func medianTrip(_ sorted: [Trip]) -> Trip? {
        guard !sorted.isEmpty else { return nil }
        return sorted[sorted.count / 2]
    }

    private enum RatingBucket {
        case liked
        case okay
        case didnt

        var scoreRange: ClosedRange<Int> {
            switch self {
            case .liked: return 70...100
            case .okay: return 40...69
            case .didnt: return 0...39
            }
        }
    }

    static func score10(_ rating: Double) -> Int {
        Int((rating * 10).rounded(.toNearestOrAwayFromZero))
    }

    static func display(_ rating: Double) -> String {
        String(format: "%.1f", (Double(score10(rating)) / 10.0))
    }

    private static func displayScore10(_ s: Int) -> String {
        String(format: "%.1f", Double(s) / 10.0)
    }
}
