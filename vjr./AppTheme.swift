//
//  AppTheme.swift
//  vjr.
//
//  Created by Emilio Lugo on 2/28/26.
//

import SwiftUI

enum AppTheme {
    private struct Palette {
        let background: Color
        let surface: Color
        let primary: Color
        let secondary: Color
        let accent: Color
        let textMain: Color
        let textMuted: Color
        let tabBarActive: Color
        let tabBarInactive: Color
        let plusBackground: Color
        let plusIcon: Color
    }

    // Dark mode palette
    // Background: #121212, Primary: #183C30, Secondary: #0A1C16, Text: #F2F2F2, Accent: #E040FB
    private static let dark = Palette(
        // background 20% darker than previous #323A34 -> ~#282E2A
        background: Color(hex: "1e201e"),
        // bars ~10% darker than background -> ~#242926
        surface: Color(hex: "1c1e1c"),
        primary: Color(hex: "9A3412"),             // deep burnt orange
        secondary: Color(hex: "7C2D12"),           // darker orange-brown
        accent: Color(hex: "F97316"),              // vibrant orange highlight
        textMain: Color(hex: "F2F2F2"),
        textMuted: Color(hex: "F2F2F2").opacity(0.7),
        tabBarActive: Color(hex: "548f7e"),
        tabBarInactive: Color(hex: "cfc9c1"),
        plusBackground: Color(hex: "559280"),
        plusIcon: Color(hex: "cfc9c1")
    )

    // Light mode palette
    // Surface(BG): #FBFCFB, Primary: #264139, Secondary: #4A635C, Accent: #D4E1DD,
    // Text(Main): #1A1C1B, Text(Muted): #5C615F
    private static let light = Palette(
        background: Color(hex: "FBFCFB"),
        surface: Color(hex: "FBFCFB"),
        primary: Color(hex: "264139"),
        secondary: Color(hex: "4A635C"),
        accent: Color(hex: "D4E1DD"),
        textMain: Color(hex: "1A1C1B"),
        textMuted: Color(hex: "5C615F"),
        tabBarActive: Color(hex: "264139"),
        tabBarInactive: Color(hex: "5C615F"),
        plusBackground: Color(hex: "264139"),
        plusIcon: Color.white
    )

    private static func palette(for scheme: ColorScheme) -> Palette {
        switch scheme {
        case .dark: return dark
        default: return light
        }
    }

    static func background(for scheme: ColorScheme) -> Color { palette(for: scheme).background }
    static func surface(for scheme: ColorScheme) -> Color { palette(for: scheme).surface }
    static func primaryText(for scheme: ColorScheme) -> Color { palette(for: scheme).textMain }
    static func secondaryText(for scheme: ColorScheme) -> Color { palette(for: scheme).textMuted }
    static func tabBarActive(for scheme: ColorScheme) -> Color { palette(for: scheme).tabBarActive }
    static func tabBarInactive(for scheme: ColorScheme) -> Color { palette(for: scheme).tabBarInactive }
    static func plusBackground(for scheme: ColorScheme) -> Color { palette(for: scheme).plusBackground }
    static func plusIcon(for scheme: ColorScheme) -> Color { palette(for: scheme).plusIcon }
}
