//
//  AuthViewModel.swift
//  FamilyTap
//
//  Backs both LoginView (AUTH-001) and SignUpView (AUTH-002). Each screen
//  owns its own instance, so login/signup form state never bleeds together.
//

import Foundation

enum SignUpOutcome {
    case success(needsEmailConfirmation: Bool)
    case failure
}

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var displayName = ""
    @Published var isLoading = false
    @Published var errorMessage: String?

    func signIn() async {
        errorMessage = nil
        guard validateCommonFields() else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            try await AuthService.shared.signIn(email: email, password: password)
        } catch {
            errorMessage = "ログインできませんでした。\nメールアドレスとパスワードをご確認ください。"
        }
    }

    func signUp() async -> SignUpOutcome {
        errorMessage = nil
        guard validateCommonFields() else { return .failure }
        guard !displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "表示名を入力してください。"
            return .failure
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let hasSession = try await AuthService.shared.signUp(
                email: email,
                password: password,
                displayName: displayName
            )
            return .success(needsEmailConfirmation: !hasSession)
        } catch {
            errorMessage = "登録できませんでした。\n時間をおいてもう一度お試しください。"
            return .failure
        }
    }

    private func validateCommonFields() -> Bool {
        guard !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, !password.isEmpty else {
            errorMessage = "メールアドレスとパスワードを入力してください。"
            return false
        }
        return true
    }
}
