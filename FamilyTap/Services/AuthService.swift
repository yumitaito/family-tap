//
//  AuthService.swift
//  FamilyTap
//
//  Wraps Supabase Auth calls (spec section 21). Views/ViewModels must go
//  through this rather than touching SupabaseService.shared.client directly.
//
//  The `profiles` row itself is NOT created here — it's created server-side
//  by the `handle_new_user` DB trigger reading the `display_name` metadata
//  passed to signUp(). That also covers the case where Supabase's "confirm
//  email" setting means there's no client session yet right after sign up,
//  when an RLS-gated client-side insert wouldn't be possible.
//

import Foundation
import Supabase

final class AuthService {
    static let shared = AuthService()

    private var client: SupabaseClient { SupabaseService.shared.client }

    private init() {}

    /// Returns `true` if sign up produced an active session immediately
    /// (email confirmation disabled), or `false` if the caller still needs
    /// to confirm their email before they can sign in.
    @discardableResult
    func signUp(email: String, password: String, displayName: String) async throws -> Bool {
        let response = try await client.auth.signUp(
            email: email,
            password: password,
            data: ["display_name": .string(displayName)]
        )
        return response.session != nil
    }

    func signIn(email: String, password: String) async throws {
        try await client.auth.signIn(email: email, password: password)
    }

    func signOut() async throws {
        try await client.auth.signOut()
    }

    /// The signed-in user's id. Throws if there is no active session —
    /// callers should only reach this from screens already gated by
    /// SessionStore, so that's a genuine error state, not an expected nil.
    func currentUserId() async throws -> UUID {
        try await client.auth.session.user.id
    }
}
