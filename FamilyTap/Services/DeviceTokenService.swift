//
//  DeviceTokenService.swift
//  FamilyTap
//
//  Registers this device's APNs token (spec section 28/35), so the
//  send-family-notification Edge Function can find it later.
//

import Foundation
import Supabase

final class DeviceTokenService {
    static let shared = DeviceTokenService()

    private var client: SupabaseClient { SupabaseService.shared.client }

    private init() {}

    /// Upserts on `token` (`device_tokens.token` is UNIQUE) — the same
    /// physical device re-registering (app relaunch, token refresh) should
    /// update the existing row rather than fail on a duplicate.
    func registerToken(_ token: String, userId: UUID) async throws {
        struct DeviceTokenUpsert: Encodable {
            let user_id: UUID
            let token: String
            let platform = "ios"
        }

        try await client
            .from("device_tokens")
            .upsert(DeviceTokenUpsert(user_id: userId, token: token), onConflict: "token")
            .execute()
    }
}
