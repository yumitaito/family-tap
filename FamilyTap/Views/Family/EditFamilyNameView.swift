//
//  EditFamilyNameView.swift
//  FamilyTap
//
//  Lets the family owner rename the family at any time from Settings
//  (spec section 44). Renaming is owner-only under RLS
//  (`families_update_owner`) — a non-owner can still open this screen and
//  try, but gets a clear error rather than a silently-ignored save.
//

import SwiftUI

struct EditFamilyNameView: View {
    let familyId: UUID
    var onSaved: () -> Void

    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: EditFamilyNameViewModel

    init(familyId: UUID, currentName: String, onSaved: @escaping () -> Void) {
        self.familyId = familyId
        self.onSaved = onSaved
        _viewModel = StateObject(wrappedValue: EditFamilyNameViewModel(currentName: currentName))
    }

    var body: some View {
        Form {
            Section("家族名") {
                TextField("例）弓田家", text: $viewModel.name)
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
                        if await viewModel.save(familyId: familyId) {
                            onSaved()
                            dismiss()
                        }
                    }
                } label: {
                    Group {
                        if viewModel.isLoading {
                            ProgressView()
                        } else {
                            Text("保存する")
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .disabled(viewModel.isLoading)
            }
        }
        .navigationTitle("家族名を編集")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        EditFamilyNameView(familyId: UUID(), currentName: "弓田家", onSaved: {})
    }
}
