//
//  EditDisplayNameView.swift
//  FamilyTap
//
//  Lets the signed-in user change their own 表示名 at any time from
//  Settings (spec section 44), not just once at signup.
//

import SwiftUI

struct EditDisplayNameView: View {
    var onSaved: () -> Void

    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: EditDisplayNameViewModel

    init(currentName: String, onSaved: @escaping () -> Void) {
        self.onSaved = onSaved
        _viewModel = StateObject(wrappedValue: EditDisplayNameViewModel(currentName: currentName))
    }

    var body: some View {
        Form {
            Section("表示名") {
                TextField("例）お父さん", text: $viewModel.displayName)
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
                        if await viewModel.save() {
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
        .navigationTitle("表示名を編集")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        EditDisplayNameView(currentName: "お父さん", onSaved: {})
    }
}
