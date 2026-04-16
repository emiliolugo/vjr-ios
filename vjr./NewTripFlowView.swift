//
//  NewTripFlowView.swift
//  vjr.
//
//  Form → rating → atomic save. See docs/TRIPS.md.

import SwiftUI

struct NewTripFlowView: View {
    @Bindable var store: TripLocalStore
    let username: String
    let userId: String

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var step: Step = .form
    @State private var draft = TripDraft()
    @State private var selectedCountries: Set<String> = []
    @State private var ratingVM: TripRatingViewModel?
    @State private var formAlert = false
    @State private var formAlertMessage = ""
    @State private var syncError: AppError?
    @State private var showSyncAlert = false

    private enum Step {
        case form
        case rating
    }

    var body: some View {
        NavigationStack {
            Group {
                switch step {
                case .form:
                    formScrollContent
                case .rating:
                    if let vm = ratingVM {
                        TripRatingStepView(
                            vm: vm,
                            draft: draft,
                            colorScheme: colorScheme,
                            onSaveTrip: { trip in
                                Task { @MainActor in
                                    await saveTrip(trip)
                                }
                            }
                        )
                    }
                }
            }
            .background(AppTheme.background(for: colorScheme))
            .foregroundStyle(AppTheme.primaryText(for: colorScheme))
            .navigationTitle(step == .form ? "New trip" : "Rate trip")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .alert("Check your trip", isPresented: $formAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(formAlertMessage)
        }
        .alert("Couldn’t update map", isPresented: $showSyncAlert) {
            Button("OK") {
                syncError = nil
                dismiss()
            }
        } message: {
            Text("Your trip was saved on this device. \(syncError?.localizedDescription ?? "")")
        }
    }

    // MARK: - Form (scroll + cards)

    private var formScrollContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                TripWizardStepBar(currentStep: 1)

                Text("Tell us where you went. You’ll rate the trip next, then save.")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.secondaryText(for: colorScheme))
                    .padding(.horizontal, 4)

                TripCardShell {
                    VStack(alignment: .leading, spacing: 12) {
                        formSectionTitle("Countries", required: true)
                        NavigationLink {
                            CountryMultiSelectView(selected: $selectedCountries)
                        } label: {
                            HStack {
                                Text(selectedCountries.isEmpty ? "Choose countries" : "\(selectedCountries.count) selected")
                                    .foregroundStyle(
                                        selectedCountries.isEmpty
                                            ? AppTheme.secondaryText(for: colorScheme)
                                            : AppTheme.primaryText(for: colorScheme)
                                    )
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(AppTheme.secondaryText(for: colorScheme))
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .padding(18)
                }

                TripCardShell {
                    VStack(alignment: .leading, spacing: 16) {
                        formSectionTitle("Dates", required: true)
                        DatePicker("Start", selection: $draft.startDate, displayedComponents: .date)
                        DatePicker("End", selection: $draft.endDate, displayedComponents: .date)
                    }
                    .padding(18)
                }

                TripCardShell {
                    VStack(alignment: .leading, spacing: 12) {
                        formSectionTitle("Caption", required: false)
                        TextField("What stood out?", text: $draft.caption, axis: .vertical)
                            .lineLimit(3...6)
                    }
                    .padding(18)
                }

                TripCardShell {
                    VStack(alignment: .leading, spacing: 14) {
                        formSectionTitle("Activities", required: false)
                        Text("Up to 5, 80 characters each")
                            .font(.caption)
                            .foregroundStyle(AppTheme.secondaryText(for: colorScheme))
                        ForEach(0..<5, id: \.self) { i in
                            TextField("Activity \(i + 1)", text: bindingForActivity(i))
                                .textFieldStyle(.plain)
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(AppTheme.background(for: colorScheme))
                                )
                        }
                    }
                    .padding(18)
                }

                TripCardShell {
                    VStack(alignment: .leading, spacing: 14) {
                        formSectionTitle("Stay & transport", required: false)
                        TextField("Hotel", text: $draft.hotelLine)
                            .textFieldStyle(.plain)
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(AppTheme.background(for: colorScheme))
                            )
                        TextField("Airline", text: $draft.airlineLine)
                            .textFieldStyle(.plain)
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(AppTheme.background(for: colorScheme))
                            )
                    }
                    .padding(18)
                }

                TripCardShell {
                    VStack(alignment: .leading, spacing: 12) {
                        formSectionTitle("Cover look", required: false)
                        Picker("Style", selection: $draft.coverPlaceholder) {
                            ForEach(TripCoverPlaceholder.allCases) { p in
                                Text(p.rawValue.capitalized).tag(p)
                            }
                        }
                        .pickerStyle(.segmented)
                        HStack(spacing: 12) {
                            ForEach(TripCoverPlaceholder.allCases) { p in
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(TripCoverPalette.linearGradient(placeholder: p, colorScheme: colorScheme))
                                    .frame(height: 44)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .strokeBorder(
                                                draft.coverPlaceholder == p
                                                    ? AppTheme.tabBarActive(for: colorScheme)
                                                    : Color.clear,
                                                lineWidth: 2
                                            )
                                    )
                                    .onTapGesture { draft.coverPlaceholder = p }
                            }
                        }
                    }
                    .padding(18)
                }

                Button(action: continueToRating) {
                    Text("Continue to rating")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(AppTheme.tabBarActive(for: colorScheme))
                        )
                        .foregroundStyle(AppTheme.plusIcon(for: colorScheme))
                }
                .padding(.top, 8)
                .padding(.bottom, 28)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
    }

    private func formSectionTitle(_ title: String, required: Bool) -> some View {
        HStack(spacing: 6) {
            Text(title)
                .font(.subheadline.weight(.semibold))
            if required {
                Text("•")
                    .foregroundStyle(AppTheme.tabBarActive(for: colorScheme))
                Text("Required")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(AppTheme.tabBarActive(for: colorScheme))
            }
        }
        .foregroundStyle(AppTheme.primaryText(for: colorScheme))
    }

    private func bindingForActivity(_ index: Int) -> Binding<String> {
        Binding(
            get: { draft.activities[index] },
            set: { draft.activities[index] = String($0.prefix(80)) }
        )
    }

    private func continueToRating() {
        guard !selectedCountries.isEmpty else {
            formAlertMessage = "Select at least one country."
            formAlert = true
            return
        }
        if draft.endDate < draft.startDate {
            formAlertMessage = "End date must be on or after the start date."
            formAlert = true
            return
        }
        draft.countryNames = selectedCountries.sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
        ratingVM = TripRatingViewModel(priorTrips: store.trips)
        step = .rating
    }

    @MainActor
    private func saveTrip(_ trip: Trip) async {
        store.add(trip)
        do {
            try await TripVisitedSync.addNewCountries(trip.countryNames, username: username, userId: userId)
            dismiss()
        } catch {
            syncError = AppError.from(error)
            showSyncAlert = true
        }
    }
}

// MARK: - Rating step

private struct TripRatingStepView: View {
    @Bindable var vm: TripRatingViewModel
    var draft: TripDraft
    var colorScheme: ColorScheme
    var onSaveTrip: (Trip) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                TripWizardStepBar(currentStep: 2)

                switch vm.phase {
                case .bucket:
                    Text("How was it?")
                        .font(.title2.bold())
                    Text("Pick the option that fits best. If this is your first trip in that range, we’ll place the score at the middle of the band.")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.secondaryText(for: colorScheme))

                    VStack(spacing: 12) {
                        bucketCard(
                            title: "I liked it",
                            subtitle: "Strong trip — lands in the 7–10 band",
                            systemImage: "face.smiling.fill",
                            prominent: true
                        ) { vm.chooseLiked() }

                        bucketCard(
                            title: "It was okay",
                            subtitle: "Middle ground — 4–6.9 band",
                            systemImage: "face.dashed.fill",
                            prominent: false
                        ) { vm.chooseOkay() }

                        bucketCard(
                            title: "I didn’t enjoy it",
                            subtitle: "Rough one — 0–3.9 band",
                            systemImage: "cloud.rain.fill",
                            prominent: false
                        ) { vm.chooseDidntEnjoy() }
                    }
                    .padding(.top, 8)

                case .question:
                    TripCardShell {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Compare")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(AppTheme.secondaryText(for: colorScheme))
                            Text(vm.prompt)
                                .font(.body)
                                .foregroundStyle(AppTheme.primaryText(for: colorScheme))
                                .fixedSize(horizontal: false, vertical: true)

                            if let ref = vm.referenceTrip {
                                HStack(spacing: 8) {
                                    Image(systemName: "mappin.and.ellipse")
                                    Text(ref.listTitle)
                                        .font(.subheadline.weight(.medium))
                                }
                                .foregroundStyle(AppTheme.tabBarActive(for: colorScheme))
                            }

                            VStack(spacing: 10) {
                                Button(action: { vm.answerMoreEnjoyable() }) {
                                    labelButton("More enjoyable", prominent: true)
                                }
                                Button(action: { vm.answerLessEnjoyable() }) {
                                    labelButton("Less enjoyable", prominent: false)
                                }
                            }
                            .padding(.top, 8)
                        }
                        .padding(20)
                    }

                case .finished(let score10):
                    let rating = Double(score10) / 10.0
                    VStack(spacing: 20) {
                        ZStack {
                            Circle()
                                .fill(AppTheme.tabBarActive(for: colorScheme).opacity(0.15))
                                .frame(width: 88, height: 88)
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 44))
                                .foregroundStyle(AppTheme.tabBarActive(for: colorScheme))
                        }

                        VStack(spacing: 8) {
                            Text("Trip rated")
                                .font(.subheadline)
                                .foregroundStyle(AppTheme.secondaryText(for: colorScheme))
                            Text(TripRatingViewModel.display(rating))
                                .font(.system(size: 44, weight: .bold, design: .rounded))
                                .foregroundStyle(AppTheme.primaryText(for: colorScheme))
                        }

                        if vm.usedBucketMedianShortcut {
                            Text("First trip in this rating band — we started you at the middle of that range. Next trips here will compare against your past ones.")
                                .font(.footnote)
                                .foregroundStyle(AppTheme.secondaryText(for: colorScheme))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 8)
                        }

                        Button {
                            let trip = draft.makeTrip(
                                id: UUID(),
                                tripRating: rating,
                                now: Date()
                            )
                            onSaveTrip(trip)
                        } label: {
                            Text("Save trip")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .fill(AppTheme.tabBarActive(for: colorScheme))
                                )
                                .foregroundStyle(AppTheme.plusIcon(for: colorScheme))
                        }
                        .padding(.top, 8)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
        .toolbar {
            if case .finished(let score10) = vm.phase {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save trip") {
                        let rating = Double(score10) / 10.0
                        let trip = draft.makeTrip(
                            id: UUID(),
                            tripRating: rating,
                            now: Date()
                        )
                        onSaveTrip(trip)
                    }
                }
            }
        }
    }

    private func bucketCard(
        title: String,
        subtitle: String,
        systemImage: String,
        prominent: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            TripCardShell {
                HStack(spacing: 16) {
                    Image(systemName: systemImage)
                        .font(.title2)
                        .foregroundStyle(
                            prominent
                                ? AppTheme.tabBarActive(for: colorScheme)
                                : AppTheme.secondaryText(for: colorScheme)
                        )
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(AppTheme.tabBarActive(for: colorScheme).opacity(prominent ? 0.2 : 0.08))
                        )

                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.headline)
                            .foregroundStyle(AppTheme.primaryText(for: colorScheme))
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(AppTheme.secondaryText(for: colorScheme))
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.secondaryText(for: colorScheme))
                }
                .padding(18)
            }
        }
        .buttonStyle(.plain)
    }

    private func labelButton(_ title: String, prominent: Bool) -> some View {
        Text(title)
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(
                        prominent
                            ? AppTheme.tabBarActive(for: colorScheme)
                            : AppTheme.surface(for: colorScheme)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(
                        prominent
                            ? Color.clear
                            : AppTheme.secondaryText(for: colorScheme).opacity(0.2),
                        lineWidth: 1
                    )
            )
            .foregroundStyle(
                prominent
                    ? AppTheme.plusIcon(for: colorScheme)
                    : AppTheme.primaryText(for: colorScheme)
            )
    }
}

// MARK: - Country multi-select

private struct CountryMultiSelectView: View {
    @Binding var selected: Set<String>
    @Environment(\.colorScheme) private var colorScheme
    @State private var search = ""

    private var shapes: [CountryShape] {
        CountryStore.shapes
            .sorted { $0.name < $1.name }
            .filter {
                search.isEmpty || $0.name.localizedCaseInsensitiveContains(search)
            }
    }

    var body: some View {
        List(shapes) { shape in
            let on = selected.contains(shape.name)
            Button {
                if on {
                    selected.remove(shape.name)
                } else {
                    selected.insert(shape.name)
                }
            } label: {
                HStack {
                    Text(shape.name)
                        .foregroundStyle(AppTheme.primaryText(for: colorScheme))
                    Spacer()
                    if on {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(AppTheme.tabBarActive(for: colorScheme))
                    }
                }
            }
            .listRowBackground(AppTheme.background(for: colorScheme))
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(AppTheme.background(for: colorScheme))
        .navigationTitle("Countries")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $search, prompt: "Search countries")
    }
}
