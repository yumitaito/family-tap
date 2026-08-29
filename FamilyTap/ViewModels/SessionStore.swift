//
//  SessionStore.swift
//  FamilyTap
//
//  App-wide auth session state, driven by Supabase's authStateChanges
//  stream. RootView reads this to decide between the Auth flow and the
//  main app (spec section 6). Sign-in/up/out anywhere in the app updates
//  this automatically — nothing needs to poke it manually.
//

import Foundation
import Supabase

@MainActor
final class SessionStore: ObservableObject {
    @Published private(set) var session: Session?
    @Published private(set) var isLoading = true

    private var authStateTask: Task<Void, Never>?

    init() {
        let client = SupabaseService.shared.client
        authStateTask = Task { [weak self] in
            for await state in client.auth.authStateChanges {
                guard let self else { return }
                self.session = state.session
                self.isLoading = false
            }
        }
    }

    deinit {
        authStateTask?.cancel()
    }
}
