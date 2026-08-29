//
//  AppDelegate.swift
//  FamilyTap
//
//  Bridges APNs' UIKit-only callbacks (spec section 35) into the SwiftUI
//  app via `@UIApplicationDelegateAdaptor` — there's no SwiftUI-native way
//  to receive `didRegisterForRemoteNotificationsWithDeviceToken`.
//

import UIKit

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        let token = deviceToken.map { String(format: "%02x", $0) }.joined()
        Task {
            do {
                let userId = try await AuthService.shared.currentUserId()
                try await DeviceTokenService.shared.registerToken(token, userId: userId)
            } catch {
                // Non-fatal: this device just won't receive push until the
                // next successful registration (e.g. next launch).
            }
        }
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        // Expected on the Simulator / without a provisioned Push
        // Notifications capability — non-fatal, push just won't work.
    }
}
