//
//  FeedView.swift
//  vjr.
//
//  Social travel recommendations and saved "want to travel" countries.

import SwiftUI

struct FeedView: View {
    let store: TripLocalStore

    @State private var recommendationsVM = DestinationRecommendationsViewModel()
    @AppStorage("wantToTravelCountries") private var savedCountriesRaw = ""
    @AppStorage("currentUsername") private var currentUsername = ""
    @AppStorage("currentUserPrismaId") private var currentUserPrismaId = ""
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedSection: FeedSection = .recommended

    private enum FeedSection {
        case recommended
        case wantToTravel
    }

    var body: some View {
        VStack(spacing: 0) {
            TabHeader {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("vjr.")
                            .font(.title.bold())
                        Text("Where next?")
                            .font(.caption)
                            .foregroundStyle(AppTheme.secondaryText(for: colorScheme))
                    }
                    Spacer()
                    recommendationBadge
                }
                .padding(.horizontal, 16)
            }

            Picker("Feed section", selection: $selectedSection) {
                Text("Recommended").tag(FeedSection.recommended)
                Text("Want to travel").tag(FeedSection.wantToTravel)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            ScrollView {
                VStack(spacing: 16) {
                    tripSignal

                    switch selectedSection {
                    case .recommended:
                        recommendedContent
                    case .wantToTravel:
                        wantToTravelContent
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 4)
                .padding(.bottom, 28)
            }
        }
        .background(AppTheme.background(for: colorScheme))
        .foregroundStyle(AppTheme.primaryText(for: colorScheme))
        .task {
            await loadRecommendations()
        }
        .onChange(of: store.trips) { _, _ in
            Task { await loadRecommendations(force: true) }
        }
    }

    private var recommendedContent: some View {
        Group {
            if recommendationsVM.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
            } else if recommendations.isEmpty {
                emptyRecommended
            } else {
                LazyVStack(spacing: 14) {
                    ForEach(recommendations) { recommendation in
                        RecommendationCard(
                            recommendation: recommendation,
                            isSaved: savedCountries.contains(recommendation.countryName),
                            onToggleSaved: { toggleSaved(recommendation.countryName) }
                        )
                    }
                }
            }
        }
    }

    private var wantToTravelContent: some View {
        Group {
            if savedCountries.isEmpty {
                emptyWantToTravel
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(savedCountries.sorted(), id: \.self) { country in
                        SavedCountryRow(
                            countryName: country,
                            recommendation: recommendations.first { $0.countryName == country },
                            onRemove: { toggleSaved(country) }
                        )
                    }
                }
            }
        }
    }

    private var tripSignal: some View {
        HStack(spacing: 10) {
            metricTile(value: "\(visitedCountries.count)", label: "visited", icon: "mappin.and.ellipse")
            metricTile(value: "\(recommendations.count)", label: "social", icon: "person.2.fill")
            metricTile(value: "\(savedCountries.count)", label: "saved", icon: "bookmark.fill")
        }
    }

    private func metricTile(value: String, label: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(AppTheme.tabBarActive(for: colorScheme))
                .frame(width: 30, height: 30)
                .background(
                    Circle()
                        .fill(AppTheme.tabBarActive(for: colorScheme).opacity(0.13))
                )

            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(.headline)
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(AppTheme.secondaryText(for: colorScheme))
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(AppTheme.surface(for: colorScheme))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(AppTheme.secondaryText(for: colorScheme).opacity(0.12), lineWidth: 1)
        )
    }

    private var recommendationBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: "person.2.fill")
                .font(.caption.weight(.bold))
            Text("\(recommendations.count)")
                .font(.caption.weight(.bold))
        }
        .foregroundStyle(AppTheme.tabBarActive(for: colorScheme))
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(
            Capsule()
                .fill(AppTheme.tabBarActive(for: colorScheme).opacity(0.14))
        )
    }

    private var emptyRecommended: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.2")
                .font(.system(size: 36, weight: .medium))
                .foregroundStyle(AppTheme.tabBarActive(for: colorScheme))
                .frame(width: 84, height: 84)
                .background(
                    Circle()
                        .fill(AppTheme.tabBarActive(for: colorScheme).opacity(0.12))
                )

            VStack(spacing: 6) {
                Text("No traveler recommendations yet")
                    .font(.headline)
                Text("Follow travelers and log trips so mutuals and nearby places can shape this feed.")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(AppTheme.secondaryText(for: colorScheme))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 46)
    }

    private var emptyWantToTravel: some View {
        VStack(spacing: 16) {
            Image(systemName: "bookmark")
                .font(.system(size: 36, weight: .medium))
                .foregroundStyle(AppTheme.tabBarActive(for: colorScheme))
                .frame(width: 84, height: 84)
                .background(
                    Circle()
                        .fill(AppTheme.tabBarActive(for: colorScheme).opacity(0.12))
                )

            VStack(spacing: 6) {
                Text("No countries saved yet")
                    .font(.headline)
                Text("Save social recommendations to shape your next trip list.")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(AppTheme.secondaryText(for: colorScheme))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 46)
    }

    private var recommendations: [DestinationRecommendation] {
        recommendationsVM.recommendations
    }

    private var visitedCountries: Set<String> {
        Set(store.trips.flatMap(\.countryNames))
    }

    private var savedCountries: Set<String> {
        Set(
            savedCountriesRaw
                .split(separator: "\n")
                .map(String.init)
                .filter { !$0.isEmpty }
        )
    }

    private func loadRecommendations(force: Bool = false) async {
        await recommendationsVM.load(
            username: currentUsername,
            prismaId: currentUserPrismaId,
            recentTrips: store.trips,
            force: force
        )
    }

    private func toggleSaved(_ countryName: String) {
        var next = savedCountries
        if next.contains(countryName) {
            next.remove(countryName)
        } else {
            next.insert(countryName)
        }
        savedCountriesRaw = next.sorted().joined(separator: "\n")
    }
}

private struct RecommendationCard: View {
    let recommendation: DestinationRecommendation
    let isSaved: Bool
    let onToggleSaved: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        TripCardShell {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 14) {
                    icon

                    VStack(alignment: .leading, spacing: 6) {
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Text(recommendation.countryName)
                                .font(.headline)
                                .foregroundStyle(AppTheme.primaryText(for: colorScheme))
                            Text(recommendation.socialSummary)
                                .font(.caption)
                                .foregroundStyle(AppTheme.secondaryText(for: colorScheme))
                        }

                        Text(recommendation.geographySummary)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(AppTheme.tabBarActive(for: colorScheme))
                    }

                    Spacer(minLength: 8)

                    Button(action: onToggleSaved) {
                        Image(systemName: isSaved ? "checkmark" : "plus")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(isSaved ? AppTheme.plusIcon(for: colorScheme) : AppTheme.tabBarActive(for: colorScheme))
                            .frame(width: 34, height: 34)
                            .background(
                                Circle()
                                    .fill(isSaved ? AppTheme.plusBackground(for: colorScheme) : AppTheme.tabBarActive(for: colorScheme).opacity(0.12))
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(isSaved ? "Remove \(recommendation.countryName)" : "Save \(recommendation.countryName)")
                }

                if !recommendation.visibleTravelers.isEmpty {
                    travelerLine
                }

                HStack(spacing: 8) {
                    Label("\(recommendation.mutualTravelers.count) mutual", systemImage: "person.2.fill")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(AppTheme.secondaryText(for: colorScheme))
                    Spacer(minLength: 0)
                    Label("Nearby weighted", systemImage: "location.fill")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(AppTheme.secondaryText(for: colorScheme))
                }
            }
            .padding(16)
        }
    }

    private var travelerLine: some View {
        let names = recommendation.visibleTravelers.joined(separator: ", ")
        let extraCount = max(0, recommendation.socialCount - recommendation.visibleTravelers.count)

        return Text(extraCount > 0 ? "\(names) and \(extraCount) more" : names)
            .font(.subheadline)
            .foregroundStyle(AppTheme.primaryText(for: colorScheme))
            .fixedSize(horizontal: false, vertical: true)
    }

    private var icon: some View {
        Image(systemName: recommendation.mutualTravelers.isEmpty ? "mappin" : "person.2.fill")
            .font(.system(size: 20, weight: .semibold))
            .foregroundStyle(AppTheme.plusIcon(for: colorScheme))
            .frame(width: 48, height: 48)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(AppTheme.plusBackground(for: colorScheme))
            )
    }
}

private struct SavedCountryRow: View {
    let countryName: String
    let recommendation: DestinationRecommendation?
    let onRemove: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: recommendation?.mutualTravelers.isEmpty == false ? "person.2.fill" : "mappin")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(AppTheme.tabBarActive(for: colorScheme))
                .frame(width: 38, height: 38)
                .background(
                    Circle()
                        .fill(AppTheme.tabBarActive(for: colorScheme).opacity(0.12))
                )

            VStack(alignment: .leading, spacing: 3) {
                Text(countryName)
                    .font(.subheadline.weight(.semibold))
                if let recommendation {
                    Text(recommendation.socialSummary)
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondaryText(for: colorScheme))
                }
            }

            Spacer(minLength: 0)

            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(AppTheme.secondaryText(for: colorScheme))
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(AppTheme.secondaryText(for: colorScheme).opacity(0.10))
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Remove \(countryName)")
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(AppTheme.surface(for: colorScheme))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(AppTheme.secondaryText(for: colorScheme).opacity(0.12), lineWidth: 1)
        )
    }
}

#Preview { @MainActor in
    FeedView(store: TripLocalStore())
}
