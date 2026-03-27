//
//  Path+SVG.swift
//  vjr.
//
//  Created by Emilio Lugo on 2/28/26.
//
//  Parses the subset of SVG path commands used in countries.json:
//    M  – absolute moveto
//    m  – relative moveto
//    l  – relative lineto (implicit after m)
//    Z/z – closepath
//  After M, subsequent coordinate pairs are treated as absolute lineto (L).
//  After m, subsequent coordinate pairs are treated as relative lineto (l).
//  Numbers may run together using minus signs as implicit delimiters (e.g. "1.8-2.9").

import SwiftUI

extension Path {
    init(svgString: String) {
        self.init()
        let scanner = Scanner(string: svgString)
        scanner.charactersToBeSkipped = CharacterSet.whitespaces.union(.init(charactersIn: ","))

        var cmd: Character = "M"
        var cx: Double = 0
        var cy: Double = 0

        while !scanner.isAtEnd {
            // Consume any command letters at the current position.
            if let letters = scanner.scanCharacters(from: .letters) {
                var onlyClosePath = true
                for c in letters {
                    switch c {
                    case "Z", "z":
                        closeSubpath()
                    default:
                        cmd = c
                        onlyClosePath = false
                    }
                }
                if onlyClosePath { continue }
            }

            // Consume a coordinate pair.
            guard let x = scanner.scanDouble(), let y = scanner.scanDouble() else { continue }

            switch cmd {
            case "M":
                move(to: CGPoint(x: x, y: y))
                cx = x; cy = y
                cmd = "L" // subsequent pairs become absolute lineto
            case "m":
                cx += x; cy += y
                move(to: CGPoint(x: cx, y: cy))
                cmd = "l" // subsequent pairs become relative lineto
            case "L":
                cx = x; cy = y
                addLine(to: CGPoint(x: cx, y: cy))
            case "l":
                cx += x; cy += y
                addLine(to: CGPoint(x: cx, y: cy))
            default:
                break
            }
        }
    }
}
