//
//  Color+Hex.swift
//  vjr.
//
//  Created by Emilio Lugo on 2/28/26.
//

import SwiftUI

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 8: // ARGB
            (a, r, g, b) = ((int & 0xFF00_0000) >> 24, (int & 0x00FF_0000) >> 16, (int & 0x0000_FF00) >> 8, int & 0x0000_00FF)
        case 6: // RGB
            (a, r, g, b) = (255, (int & 0xFF00_00) >> 16, (int & 0x00FF_00) >> 8, int & 0x0000_FF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
