//
//  ToastView.swift
//  FamilyTap
//
//  Report-completion feedback (spec section 34: "報告しました ✓") and
//  lightweight report-failure feedback (spec section 45).
//

import SwiftUI

enum ToastState: Equatable {
    case success(String)
    case failure(String)

    var message: String {
        switch self {
        case .success(let message), .failure(let message):
            message
        }
    }

    var tint: Color {
        switch self {
        case .success: .primary
        case .failure: .red
        }
    }
}

struct ToastView: View {
    let state: ToastState

    var body: some View {
        Text(state.message)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(state.tint)
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(.thinMaterial, in: Capsule())
            .shadow(radius: 4, y: 2)
    }
}

#Preview {
    VStack(spacing: 16) {
        ToastView(state: .success("報告しました ✓"))
        ToastView(state: .failure("報告できませんでした。"))
    }
}
