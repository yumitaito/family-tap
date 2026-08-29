//
//  RootView.swift
//  FamilyTap
//
//  Top of the view hierarchy — gates on auth state, then family-group
//  membership (spec section 6):
//  未ログイン → 認証画面 / ログイン済み・未参加 → 家族を作る/参加する / 参加済み → ホーム.
//

import SwiftUI

struct RootView: View {
    @StateObject private var sessionStore = SessionStore()

    var body: some View {
        Group {
            if sessionStore.isLoading {
                ProgressView()
            } else if let session = sessionStore.session {
                AuthenticatedRootView(userId: session.user.id)
                    .id(session.user.id) // fresh FamilyStore if the signed-in user changes
            } else {
                LoginView()
            }
        }
    }
}

/// Gates on family-group membership once we know the user is signed in.
/// Split out from RootView so `.id(userId)` above can force this (and its
/// FamilyStore) to reset cleanly across sign-out/sign-in-as-different-user.
private struct AuthenticatedRootView: View {
    let userId: UUID

    @StateObject private var familyStore = FamilyStore()

    var body: some View {
        Group {
            if familyStore.isLoading {
                ProgressView()
            } else if familyStore.family != nil {
                RootTabView()
                    .environmentObject(familyStore)
            } else {
                FamilyGateView()
                    .environmentObject(familyStore)
            }
        }
        .task { await familyStore.refresh() }
    }
}

#Preview {
    RootView()
}
