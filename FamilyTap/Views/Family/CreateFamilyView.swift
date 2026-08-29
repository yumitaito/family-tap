//
//  CreateFamilyView.swift
//  FamilyTap
//
//  FAMILY-002 (spec section 17). On success, swaps in-place to
//  InviteCodeResultView rather than pushing a new stack entry — there's no
//  reason to let the user navigate "back" to the create form once the
//  family already exists.
//

import SwiftUI

struct CreateFamilyView: View {
    @EnvironmentObject private var familyStore: FamilyStore
    @StateObject private var viewModel = FamilyViewModel()

    var body: some View {
        Group {
            if let createdFamily = viewModel.createdFamily {
                InviteCodeResultView(family: createdFamily) {
                    Task { await familyStore.refresh() }
                }
            } else {
                Form {
                    Section("家族名") {
                        TextField("例）弓田家", text: $viewModel.familyName)
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
                            Task { await viewModel.createFamily() }
                        } label: {
                            Group {
                                if viewModel.isLoading {
                                    ProgressView()
                                } else {
                                    Text("作成する")
                                }
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .disabled(viewModel.isLoading)
                    }
                }
                .navigationTitle("家族を作成")
                .navigationBarTitleDisplayMode(.inline)
            }
        }
    }
}

#Preview {
    NavigationStack {
        CreateFamilyView()
            .environmentObject(FamilyStore())
    }
}
