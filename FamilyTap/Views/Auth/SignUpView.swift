//
//  SignUpView.swift
//  FamilyTap
//
//  AUTH-002 (spec section 7, 20, 21). Collects the display name up front
//  since it's required by `profiles.display_name NOT NULL` and there's no
//  Apple-provided name to fall back on with Email/Password auth.
//

import SwiftUI

struct SignUpView: View {
    @StateObject private var viewModel = AuthViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var needsEmailConfirmationAlert = false

    var body: some View {
        Form {
            Section("表示名") {
                TextField("例）お父さん", text: $viewModel.displayName)
                    .textInputAutocapitalization(.never)
            }

            Section("ログイン情報") {
                TextField("メールアドレス", text: $viewModel.email)
                    .textContentType(.username)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                SecureField("パスワード（6文字以上）", text: $viewModel.password)
                    .textContentType(.newPassword)
            }

            if let errorMessage = viewModel.errorMessage {
                Section {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
            }

            Section {
                Button {
                    Task {
                        switch await viewModel.signUp() {
                        case .success(let needsEmailConfirmation):
                            if needsEmailConfirmation {
                                needsEmailConfirmationAlert = true
                            }
                        // If a session came back immediately, SessionStore
                        // picks it up via authStateChanges and RootView
                        // swaps to the main app on its own — nothing to do.
                        case .failure:
                            break
                        }
                    }
                } label: {
                    Group {
                        if viewModel.isLoading {
                            ProgressView()
                        } else {
                            Text("登録する")
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .disabled(viewModel.isLoading)
            }
        }
        .navigationTitle("新規登録")
        .navigationBarTitleDisplayMode(.inline)
        .alert("確認メールを送信しました", isPresented: $needsEmailConfirmationAlert) {
            Button("OK") { dismiss() }
        } message: {
            Text("メール内のリンクを開いて登録を完了してから、ログインしてください。")
        }
    }
}

#Preview {
    NavigationStack {
        SignUpView()
    }
}
