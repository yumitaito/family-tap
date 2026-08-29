//
//  JoinFamilyView.swift
//  FamilyTap
//
//  FAMILY-003 (spec section 18).
//

import SwiftUI

struct JoinFamilyView: View {
    @EnvironmentObject private var familyStore: FamilyStore
    @StateObject private var viewModel = FamilyViewModel()

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Text("家族に参加する")
                .font(.title2.bold())

            Text("招待コードを入力してください")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            TextField("例）ABCD1234", text: $viewModel.inviteCodeInput)
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
                .multilineTextAlignment(.center)
                .font(.title3.monospaced())
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }

            Button {
                Task {
                    if await viewModel.joinFamily() {
                        await familyStore.refresh()
                    }
                }
            } label: {
                Group {
                    if viewModel.isLoading {
                        ProgressView()
                    } else {
                        Text("参加する")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 50)
                .contentShape(Rectangle())
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(viewModel.isLoading)

            NavigationLink {
                CreateFamilyView()
            } label: {
                Text("コードをお持ちでない場合は家族を作成する")
                    .font(.footnote)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .contentShape(Rectangle())
            }

            Spacer()
        }
        .padding()
        .navigationTitle("家族に参加")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        JoinFamilyView()
            .environmentObject(FamilyStore())
    }
}
