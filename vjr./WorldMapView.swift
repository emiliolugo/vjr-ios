//
//  WorldMapView.swift
//  vjr.
//
//  Created by Emilio Lugo on 2/28/26.
//
//  Renders the world map from countries.json using SwiftUI Canvas.
//  All 221 country shapes are drawn in a single pass for performance.
//  Pass visitedKeys to highlight visited countries.

import SwiftUI

struct WorldMapView: View {
    /// Keys of visited countries (matches the `key` field in countries.json).
    var visitedKeys: Set<String> = []

    @Environment(\.colorScheme) private var colorScheme

    // The coordinate space of the SVG data in countries.json.
    private static let mapWidth: Double  = 2000
    private static let mapHeight: Double = 860

    var body: some View {
        GeometryReader { geo in
            let scale = geo.size.width / Self.mapWidth
            let transform = CGAffineTransform(scaleX: scale, y: scale)

            Canvas { context, _ in
                for shape in CountryStore.shapes {
                    let scaled = shape.path.applying(transform)
                    let visited = visitedKeys.contains(shape.id)

                    context.fill(scaled, with: .color(visited ? visitedColor : baseColor))
                    context.stroke(scaled, with: .color(borderColor), lineWidth: 0.5)
                }
            }
        }
        .aspectRatio(Self.mapWidth / Self.mapHeight, contentMode: .fit)
    }

    private var baseColor: Color {
        colorScheme == .dark
            ? Color(hex: "2e3b35")
            : Color(hex: "c8dbd5")
    }

    private var visitedColor: Color {
        colorScheme == .dark
            ? Color(hex: "548f7e")
            : Color(hex: "264139")
    }

    private var borderColor: Color {
        colorScheme == .dark
            ? Color.black.opacity(0.5)
            : Color.white.opacity(0.6)
    }
}

#Preview {
    WorldMapView(visitedKeys: ["United States", "France", "Japan", "Brazil", "Australia"])
        .padding()
}
