//
//  Country.swift
//  vjr.
//
//  Created by Emilio Lugo on 2/28/26.
//

import SwiftUI

struct Country: Codable, Identifiable {
    var id: String { key }
    let key: String
    let name: String
    let paths: [String]
}

/// Pre-parsed country shape ready for Canvas rendering.
struct CountryShape: Identifiable {
    let id: String
    let name: String
    let path: Path          // all SVG segments combined into one Path
}

enum CountryStore {
    /// All 221 country shapes, parsed once at launch.
    /// Requires `countries.json` to be added to the app target (not inside Assets.xcassets).
    static let shapes: [CountryShape] = {
        guard
            let url = Bundle.main.url(forResource: "countries", withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let countries = try? JSONDecoder().decode([Country].self, from: data)
        else {
            print("⚠️ CountryStore: countries.json not found in bundle. Move it out of Assets.xcassets and add it to the app target.")
            return []
        }

        return countries.map { country in
            var combined = Path()
            for svg in country.paths {
                combined.addPath(Path(svgString: svg))
            }
            return CountryShape(id: country.key, name: country.name, path: combined)
        }
    }()
}
