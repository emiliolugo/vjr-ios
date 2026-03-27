//
//  LoginView.swift
//  vjr.
//
//  Simplified auth for local testing (no Clerk).
//  Enter a username → fetch user from Vapor → store session in AppStorage.

import SwiftUI

struct LoginView: View {
    @AppStorage("currentUsername")      private var currentUsername      = ""
    @AppStorage("currentUserId")        private var currentUserId        = ""
    @AppStorage("currentUserPrismaId")  private var currentUserPrismaId  = ""
    @AppStorage("currentUserIsPrivate") private var currentUserIsPrivate = false

    @State private var inputUsername = ""
    @State private var isLoading     = false
    @State private var errorMessage: String?

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // App name
            Text("vjr.")
                .font(.system(size: 64, weight: .black))
                .foregroundStyle(AppTheme.primaryText(for: colorScheme))

            Text("where have you been?")
                .font(.subheadline)
                .foregroundStyle(AppTheme.secondaryText(for: colorScheme))
                .padding(.bottom, 48)

            // Username field
            TextField("username", text: $inputUsername)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(AppTheme.surface(for: colorScheme))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(AppTheme.secondaryText(for: colorScheme).opacity(0.3), lineWidth: 1)
                )
                .padding(.horizontal, 32)

            // Error message
            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding(.top, 8)
                    .padding(.horizontal, 32)
            }

            // Continue button
            Button(action: login) {
                Group {
                    if isLoading {
                        ProgressView()
                            .tint(AppTheme.primaryText(for: colorScheme))
                    } else {
                        Text("Continue")
                            .font(.headline)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(AppTheme.surface(for: colorScheme))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(AppTheme.secondaryText(for: colorScheme).opacity(0.3), lineWidth: 1)
                )
            }
            .disabled(inputUsername.trimmingCharacters(in: .whitespaces).isEmpty || isLoading)
            .padding(.top, 16)
            .padding(.horizontal, 32)

            Spacer()
            Spacer()
        }
        .background(AppTheme.background(for: colorScheme))
        .foregroundStyle(AppTheme.primaryText(for: colorScheme))
    }

    private func login() {
        let username = inputUsername.trimmingCharacters(in: .whitespaces)
        guard !username.isEmpty else { return }

        isLoading = true
        errorMessage = nil

        Task {
            defer { isLoading = false }
            do {
                let user: User = try await APIClient.shared.fetch("api/user/\(username)")
                currentUsername      = user.username
                currentUserId        = user.userId
                currentUserPrismaId  = user.id
                currentUserIsPrivate = user.isPrivate
            } catch {
                errorMessage = "User not found. Check the username and try again."
            }
        }
    }
}

#Preview {
    LoginView()
}
