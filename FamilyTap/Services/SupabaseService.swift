//
//  SupabaseService.swift
//  FamilyTap
//
//  Owns the single shared SupabaseClient instance. Other Service types
//  (AuthService, FamilyService, ReportService, NotificationService) should
//  read `SupabaseService.shared.client` rather than constructing their own
//  client — Views must never talk to Supabase directly (spec section 54).
//

import Foundation
import Supabase

final class SupabaseService {
    static let shared = SupabaseService()

    let client: SupabaseClient

    private init() {
        guard let url = URL(string: Secrets.supabaseURLString) else {
            fatalError("Secrets.supabaseURLString is not a valid URL: \(Secrets.supabaseURLString)")
        }
        client = SupabaseClient(supabaseURL: url, supabaseKey: Secrets.supabaseAnonKey)
    }
}
