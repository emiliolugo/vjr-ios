//
//  TripsView.swift
//  vjr.
//
//  Local-first trip list. See docs/TRIPS.md.

import SwiftUI

struct TripsView: View {
    @Bindable var store: TripLocalStore
    @AppStorage("currentUsername") private var currentUsername = ""
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                TabHeader {
                    VStack(spacing: 4) {
                        Text("Trips")
                            .font(.headline)
                        if !store.trips.isEmpty {
                            Text("\(store.trips.count) saved")
                                .font(.caption)
                                .foregroundStyle(AppTheme.secondaryText(for: colorScheme))
                        }
                    }
                }

                if store.trips.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVStack(spacing: 14) {
                            ForEach(store.trips) { trip in
                                NavigationLink(value: trip) {
                                    TripListCard(trip: trip)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 28)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AppTheme.background(for: colorScheme))
            .foregroundStyle(AppTheme.primaryText(for: colorScheme))
            .navigationDestination(for: Trip.self) { trip in
                TripDetailView(trip: trip)
            }
            .onAppear {
                store.setContext(username: currentUsername)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()
            ZStack {
                Circle()
                    .fill(AppTheme.tabBarActive(for: colorScheme).opacity(0.12))
                    .frame(width: 120, height: 120)
                Image(systemName: "airplane.departure")
                    .font(.system(size: 44, weight: .medium))
                    .foregroundStyle(AppTheme.tabBarActive(for: colorScheme))
            }
            VStack(spacing: 8) {
                Text("Your trips live here")
                    .font(.title3.weight(.semibold))
                Text("Tap the + button to log a trip, rate it, and sync countries to your map.")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(AppTheme.secondaryText(for: colorScheme))
                    .padding(.horizontal, 36)
            }
            Spacer()
        }
    }
}

// MARK: - List card

private struct TripListCard: View {
    let trip: Trip
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        TripCardShell {
            HStack(alignment: .center, spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(TripCoverPalette.linearGradient(placeholder: trip.coverPlaceholder, colorScheme: colorScheme))
                        .frame(width: 76, height: 76)
                    Image(systemName: "camera.filters")
                        .font(.title2)
                        .foregroundStyle(AppTheme.plusIcon(for: colorScheme).opacity(0.9))
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(trip.listTitle)
                        .font(.headline)
                        .foregroundStyle(AppTheme.primaryText(for: colorScheme))
                        .multilineTextAlignment(.leading)
                    Text(shortDateRange)
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondaryText(for: colorScheme))
                }

                Spacer(minLength: 8)

                TripRatingPill(text: TripRatingViewModel.display(trip.tripRating))
            }
            .padding(16)
        }
    }

    private var shortDateRange: String {
        let f = DateFormatter()
        f.dateStyle = .medium
        return "\(f.string(from: trip.startDate)) – \(f.string(from: trip.endDate))"
    }
}

#Preview { @MainActor in
    TripsView(store: TripLocalStore())
}
