//
//  FamilyMembersView.swift
//  FamilyTap
//
//  FAMILY-004 (spec section 19). Also the only place to re-check the
//  family's invite code after creation — InviteCodeResultView only shows
//  it once, right when the family is created (spec section 17).
//

import SwiftUI

struct FamilyMembersView: View {
    let family: Family

    @StateObject private var viewModel = FamilyMembersViewModel()
    @State private var didCopyInviteCode = false

    var body: some View {
        List {
            Section {
                LabeledContent("家族名", value: family.name)
            }

            Section {
                HStack {
                    Text(family.inviteCode)
                        .font(.system(.body, design: .monospaced))
                        .tracking(1)
                    Spacer()
                    Button {
                        UIPasteboard.general.string = family.inviteCode
                        didCopyInviteCode = true
                    } label: {
                        Text(didCopyInviteCode ? "コピーしました" : "コピー")
                            .font(.subheadline)
                    }
                    .buttonStyle(.borderless)
                }
            } header: {
                Text("招待コード")
            } footer: {
                Text("このコードを家族に共有すると、新しいメンバーが参加できます。")
            }

            Section("メンバー一覧") {
                if viewModel.isLoading {
                    ProgressView()
                } else if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                } else if viewModel.members.isEmpty {
                    Text("メンバーがいません")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(viewModel.members) { member in
                        HStack {
                            Text(member.profile.displayName)
                            Spacer()
                            if member.role == "owner" {
                                Text("オーナー")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("家族メンバー")
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.load(familyId: family.id) }
    }
}

#Preview {
    NavigationStack {
        FamilyMembersView(
            family: Family(id: UUID(), name: "弓田家", inviteCode: "ABCD1234", createdBy: UUID(), createdAt: .now)
        )
    }
}
