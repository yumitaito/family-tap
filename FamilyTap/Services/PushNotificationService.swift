//
//  PushNotificationService.swift
//  FamilyTap
//
//  Fires the `send-family-notification` Edge Function after a report is
//  created (spec section 11 step 6 / 48). This is best-effort: a push
//  failing (e.g. no APNs credentials configured, network hiccup) must
//  never surface as "report failed" to the user — the report itself
//  already succeeded by the time this runs.
//

import Foundation
import Supabase

enum PushNotificationService {
    static func notifyFamily(reportId: UUID) async {
        struct RequestBody: Encodable {
            let reportId: String
        }

        do {
            try await SupabaseService.shared.client.functions.invoke(
                "send-family-notification",
                options: FunctionInvokeOptions(body: RequestBody(reportId: reportId.uuidString))
            )
        } catch {
            // Non-fatal — see comment above.
        }
    }
}
