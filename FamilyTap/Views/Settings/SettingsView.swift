//
//  SettingsView.swift
//  FamilyTap
//
//  SETTINGS-001 (spec section 44). Fully wired to real data as of Phase 14.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var familyStore: FamilyStore
    @StateObject private var viewModel = SettingsViewModel()

    var body: some View {
        NavigationStack {
            List {
                Section("プロフィール") {
                    NavigationLink {
                        EditDisplayNameView(currentName: viewModel.displayName ?? "") {
                            Task { await viewModel.loadProfile() }
                        }
                    } label: {
                        LabeledContent("表示名", value: viewModel.displayName ?? "-")
                    }
                }
                Section("家族") {
                    if let family = familyStore.family {
                        NavigationLink {
                            EditFamilyNameView(familyId: family.id, currentName: family.name) {
                                Task { await familyStore.refresh() }
                            }
                        } label: {
                            LabeledContent("家族", value: family.name)
                        }
                        NavigationLink("家族メンバー") {
                            FamilyMembersView(family: family)
                        }
                    } else {
                        LabeledContent("家族", value: "-")
                    }
                }
                Section("通知") {
                    NavigationLink("通知設定") {
                        NotificationSettingsView()
                    }
                }
                Section {
                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                    Button(role: .destructive) {
                        Task { await viewModel.signOut() }
                    } label: {
                        if viewModel.isLoading {
                            ProgressView()
                        } else {
                            Text("ログアウト")
                        }
                    }
                    .disabled(viewModel.isLoading)
                }
            }
            .navigationTitle("設定")
            .task { await viewModel.loadProfile() }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(FamilyStore())
}
