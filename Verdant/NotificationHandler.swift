//
//  NotificationHandler.swift
//  Verdant
//
//  Created by Ryan Tessier on 12/3/2026.
//

import Foundation
import UserNotifications
import SwiftUI

// MARK: - Notification Delegate

@MainActor
class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    
    // Handle notification when app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        // Show banner and play sound even when app is active
        return [.banner, .sound]
    }
    
    // Handle notification tap
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let userInfo = response.notification.request.content.userInfo
        
        switch response.actionIdentifier {
        case "OPEN_HOME_APP":
            await openHomeApp()
            
        case UNNotificationDefaultActionIdentifier:
            // User tapped the notification itself
            if let sensorId = userInfo["sensorId"] as? String {
                // Could navigate to the specific plant detail view
                print("📱 User tapped notification for sensor: \(sensorId)")
            }
            
        case "DISMISS":
            // User explicitly dismissed
            print("✓ User dismissed sensor notification")
            
        default:
            break
        }
    }
    
    private func openHomeApp() async {
        if let url = URL(string: "com.apple.Home://") {
            await UIApplication.shared.open(url)
        }
    }
}
