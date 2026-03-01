//
//  FeedView.swift
//  vjr.
//
//  Created by Emilio Lugo on 2/28/26.
//

import SwiftUI

struct FeedView: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 0) {
            TabHeader {
                HStack {
                    Text("vjr.")
                        .font(.title.bold())
                    Spacer()
                }
                .padding(.horizontal, 16)
            }

            Text("Feed")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(AppTheme.background(for: colorScheme))
        .foregroundStyle(AppTheme.primaryText(for: colorScheme))
    }
}

#Preview {
    FeedView()
}
