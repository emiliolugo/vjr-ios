//
//  TripVisuals.swift
//  vjr.
//
//  Shared trip UI: gradients, cards, pills (AppTheme-only colors).

import SwiftUI

// MARK: - Cover

/// Use for `Shape.fill(_:)` — `LinearGradient` conforms to `ShapeStyle`.
enum TripCoverPalette {
    static func linearGradient(placeholder: TripCoverPlaceholder, colorScheme: ColorScheme) -> LinearGradient {
        LinearGradient(
            colors: colors(for: placeholder, colorScheme: colorScheme),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private static func colors(for placeholder: TripCoverPlaceholder, colorScheme: ColorScheme) -> [Color] {
        switch placeholder {
        case .moss:
            [
                AppTheme.plusBackground(for: colorScheme),
                AppTheme.tabBarActive(for: colorScheme).opacity(0.8),
            ]
        case .slate:
            [
                AppTheme.surface(for: colorScheme),
                AppTheme.tabBarInactive(for: colorScheme).opacity(0.45),
            ]
        case .rust:
            [
                AppTheme.tabBarActive(for: colorScheme).opacity(0.9),
                AppTheme.plusBackground(for: colorScheme).opacity(0.75),
            ]
        case .ocean:
            [
                AppTheme.tabBarActive(for: colorScheme).opacity(0.4),
                AppTheme.plusBackground(for: colorScheme),
            ]
        }
    }
}

struct TripCoverGradient: View {
    let placeholder: TripCoverPlaceholder
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        TripCoverPalette.linearGradient(placeholder: placeholder, colorScheme: colorScheme)
    }
}

// MARK: - Surfaces

struct TripCardShell<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(AppTheme.surface(for: colorScheme))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(AppTheme.secondaryText(for: colorScheme).opacity(0.12), lineWidth: 1)
            )
            .shadow(
                color: Color.black.opacity(colorScheme == .dark ? 0.35 : 0.07),
                radius: 14,
                x: 0,
                y: 6
            )
    }
}

struct TripWizardStepBar: View {
    let currentStep: Int
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 10) {
            stepChip(title: "Details", step: 1)
            Image(systemName: "chevron.compact.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.secondaryText(for: colorScheme))
            stepChip(title: "Rate", step: 2)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }

    private func stepChip(title: String, step: Int) -> some View {
        let on = currentStep == step
        let done = currentStep > step
        return HStack(spacing: 6) {
            Image(systemName: done ? "checkmark.circle.fill" : "circle.fill")
                .font(.caption)
                .foregroundStyle(
                    done || on
                        ? AppTheme.tabBarActive(for: colorScheme)
                        : AppTheme.secondaryText(for: colorScheme).opacity(0.35)
                )
            Text(title)
                .font(.subheadline.weight(on ? .semibold : .medium))
                .foregroundStyle(
                    on || done
                        ? AppTheme.primaryText(for: colorScheme)
                        : AppTheme.secondaryText(for: colorScheme)
                )
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(
                    on
                        ? AppTheme.tabBarActive(for: colorScheme).opacity(0.14)
                        : AppTheme.surface(for: colorScheme)
                )
        )
        .overlay(
            Capsule()
                .strokeBorder(
                    on
                        ? AppTheme.tabBarActive(for: colorScheme).opacity(0.35)
                        : AppTheme.secondaryText(for: colorScheme).opacity(0.12),
                    lineWidth: 1
                )
        )
    }
}

struct TripRatingPill: View {
    let text: String
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Text(text)
            .font(.subheadline.weight(.semibold))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(AppTheme.tabBarActive(for: colorScheme).opacity(0.18))
            )
            .foregroundStyle(AppTheme.tabBarActive(for: colorScheme))
    }
}
