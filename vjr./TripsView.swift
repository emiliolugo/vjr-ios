//
//  TripsView.swift
//  vjr.
//
//  Created by Emilio Lugo on 2/28/26.
//

import SwiftUI

struct TripsView: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 0) {
            TabHeader {
                ZStack {
                    Text("My Trips")
                        .font(.headline)
                    HStack {
                        Spacer()
                        Button(action: {}) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 18))
                        }
                        .padding(.trailing, 16)
                    }
                }
            }

            Text("Trips")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(AppTheme.background(for: colorScheme))
        .foregroundStyle(AppTheme.primaryText(for: colorScheme))
    }
}

#Preview {
    TripsView()
}
