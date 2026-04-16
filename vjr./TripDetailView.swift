//
//  TripDetailView.swift
//  vjr.
//

import SwiftUI

struct TripDetailView: View {
    let trip: Trip
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                hero

                VStack(alignment: .leading, spacing: 20) {
                    Text(trip.listTitle)
                        .font(.title.bold())
                        .foregroundStyle(AppTheme.primaryText(for: colorScheme))

                    HStack(spacing: 10) {
                        detailPill(icon: "calendar", text: dateRangeShort)
                        TripRatingPill(text: TripRatingViewModel.display(trip.tripRating))
                    }

                    if !trip.caption.isEmpty {
                        TripCardShell {
                            VStack(alignment: .leading, spacing: 8) {
                                sectionHeader("Caption")
                                Text(trip.caption)
                                    .font(.body)
                                    .foregroundStyle(AppTheme.primaryText(for: colorScheme))
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(18)
                        }
                    }

                    if !trip.countryNames.isEmpty {
                        TripCardShell {
                            VStack(alignment: .leading, spacing: 12) {
                                sectionHeader("Countries")
                                LazyVGrid(
                                    columns: [GridItem(.adaptive(minimum: 140), spacing: 8)],
                                    alignment: .leading,
                                    spacing: 8
                                ) {
                                    ForEach(trip.countryNames, id: \.self) { c in
                                        Text(c)
                                            .font(.subheadline)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .background(
                                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                    .fill(AppTheme.background(for: colorScheme))
                                            )
                                            .foregroundStyle(AppTheme.primaryText(for: colorScheme))
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(18)
                        }
                    }

                    if !trip.activities.isEmpty {
                        TripCardShell {
                            VStack(alignment: .leading, spacing: 12) {
                                sectionHeader("Activities")
                                VStack(alignment: .leading, spacing: 10) {
                                    ForEach(Array(trip.activities.enumerated()), id: \.offset) { i, a in
                                        HStack(alignment: .top, spacing: 10) {
                                            Text("\(i + 1)")
                                                .font(.caption2.weight(.bold))
                                                .foregroundStyle(AppTheme.plusIcon(for: colorScheme))
                                                .frame(width: 22, height: 22)
                                                .background(Circle().fill(AppTheme.tabBarActive(for: colorScheme).opacity(0.22)))
                                            Text(a)
                                                .font(.subheadline)
                                                .foregroundStyle(AppTheme.primaryText(for: colorScheme))
                                        }
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(18)
                        }
                    }

                    if !trip.hotels.isEmpty || !trip.airlines.isEmpty {
                        TripCardShell {
                            VStack(alignment: .leading, spacing: 14) {
                                if !trip.hotels.isEmpty {
                                    sectionHeader("Stay")
                                    ForEach(trip.hotels, id: \.self) { h in
                                        detailPill(icon: "bed.double.fill", text: h)
                                    }
                                }
                                if !trip.airlines.isEmpty {
                                    sectionHeader("Flights")
                                    ForEach(trip.airlines, id: \.self) { a in
                                        detailPill(icon: "airplane", text: a)
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(18)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 32)
            }
        }
        .background(AppTheme.background(for: colorScheme))
        .foregroundStyle(AppTheme.primaryText(for: colorScheme))
        .navigationBarTitleDisplayMode(.inline)
    }

    private var hero: some View {
        ZStack(alignment: .bottomLeading) {
            TripCoverGradient(placeholder: trip.coverPlaceholder)
                .frame(height: 220)
                .overlay {
                    LinearGradient(
                        colors: [
                            .clear,
                            AppTheme.background(for: colorScheme).opacity(0.95),
                        ],
                        startPoint: .center,
                        endPoint: .bottom
                    )
                }

            Image(systemName: "airplane.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(AppTheme.plusIcon(for: colorScheme))
                .shadow(color: .black.opacity(0.25), radius: 6, y: 2)
                .frame(maxWidth: .infinity)
                .padding(.bottom, 36)
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.caption.weight(.semibold))
            .tracking(0.6)
            .foregroundStyle(AppTheme.secondaryText(for: colorScheme))
    }

    private func detailPill(icon: String, text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption.weight(.semibold))
            Text(text)
                .font(.subheadline)
        }
        .foregroundStyle(AppTheme.primaryText(for: colorScheme))
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(AppTheme.background(for: colorScheme))
        )
    }

    private var dateRangeShort: String {
        let f = DateFormatter()
        f.dateStyle = .medium
        return "\(f.string(from: trip.startDate)) – \(f.string(from: trip.endDate))"
    }
}
