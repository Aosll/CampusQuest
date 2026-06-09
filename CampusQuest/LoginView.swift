//
//  LoginView.swift
//  CampusQuest
//
//  The authentication gate shown when the user is signed out. Offers
//  Sign in with Apple (the official button, as Apple requires) and a
//  secondary "Continue as Guest" option. No networking here: signing in
//  only updates local AuthManager state.
//

import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @Environment(AuthManager.self) private var auth

    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            CampusBackground()

            VStack(spacing: 0) {
                Spacer()

                CampusLogo()

                Spacer()

                VStack(spacing: 14) {
                    // Official Sign in with Apple button (required by Apple).
                    SignInWithAppleButton(.signIn) { request in
                        request.requestedScopes = [.fullName, .email]
                    } onCompletion: { result in
                        handle(result)
                    }
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 52)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.control))

                    // Secondary, less prominent guest option.
                    Button {
                        auth.continueAsGuest()
                    } label: {
                        Text("Continue as Guest")
                            .font(.subheadline.bold())
                            .foregroundStyle(AppColor.primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.white.opacity(0.85),
                                        in: RoundedRectangle(cornerRadius: AppRadius.control))
                            .overlay(
                                RoundedRectangle(cornerRadius: AppRadius.control)
                                    .strokeBorder(AppColor.primary.opacity(0.25), lineWidth: 1)
                            )
                    }
                    .buttonStyle(PressableButtonStyle())

                    Text("Guest mode keeps your progress on this device only. No account, no cloud sync, no leaderboard — and no personal data or statistics are collected or stored.")
                        .font(.caption)
                        .foregroundStyle(AppColor.inkSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.top, 2)
                        .padding(.horizontal, 4)

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.caption.bold())
                            .foregroundStyle(AppColor.warning)
                            .multilineTextAlignment(.center)
                            .transition(.opacity)
                    }
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 32)
            }
        }
        .preferredColorScheme(.light)
    }

    // MARK: - Apple sign-in handling

    private func handle(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                showError("Could not read your Apple credential. Please try again.")
                return
            }
            // Apple only returns the name on the first authorization.
            let nameParts = [credential.fullName?.givenName, credential.fullName?.familyName]
                .compactMap { $0 }
                .filter { !$0.isEmpty }
            let displayName = nameParts.isEmpty ? nil : nameParts.joined(separator: " ")
            withAnimation { errorMessage = nil }
            auth.signInApple(userID: credential.user, displayName: displayName)

        case .failure(let error):
            // Cancellation is not an error worth shouting about.
            if let authError = error as? ASAuthorizationError, authError.code == .canceled {
                return
            }
            showError("Sign in didn't complete. You can try again or continue as a guest.")
        }
    }

    private func showError(_ message: String) {
        withAnimation { errorMessage = message }
    }
}

/// The shared Campus Quest logo block (icon + title + tagline), matching
/// the home screen styling.
struct CampusLogo: View {
    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 22)
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 0.36, green: 0.52, blue: 0.96),
                                     Color(red: 0.55, green: 0.40, blue: 0.92)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 96, height: 96)
                    .shadow(color: .black.opacity(0.15), radius: 10, y: 5)
                Image(systemName: "graduationcap.fill")
                    .font(.system(size: 46))
                    .foregroundStyle(.white)
            }
            Text("CampusQuest Academy")
                .font(.system(size: 38, weight: .heavy, design: .rounded))
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.7)
                .foregroundStyle(AppColor.ink)
            Text("Find words. Build your future.")
                .font(.subheadline)
                .foregroundStyle(AppColor.inkSecondary)
        }
    }
}

#Preview {
    LoginView()
        .environment(AuthManager())
}
