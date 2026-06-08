//
//  NotificationManager.swift
//  CampusQuest
//
//  Schedules a daily local reminder to bring the player back. Local
//  notifications need no special Info.plist key or capability — only the
//  user's permission, which we ask for after the player finishes a level
//  (not on first launch).
//
//  The on/off choice is stored in UserDefaults so it survives restarts and
//  can be toggled from Settings.
//

import Foundation
import UserNotifications

@MainActor
final class NotificationManager {
    static let shared = NotificationManager()

    private let center = UNUserNotificationCenter.current()
    private let defaults = UserDefaults.standard

    /// Identifier for the repeating daily reminder, so we can find and replace it.
    private let dailyReminderID = "campusquest.dailyReminder"
    /// Hour of day (24h) the reminder fires at.
    private let reminderHour = 19

    private enum Keys {
        static let enabled = "notifications.enabled"
        static let asked = "notifications.askedOnce"
    }

    private init() {}

    /// Whether the player wants daily reminders. Defaults to true so a granted
    /// permission starts reminding right away; turning the toggle off persists.
    var isEnabled: Bool {
        get { defaults.object(forKey: Keys.enabled) as? Bool ?? true }
        set { defaults.set(newValue, forKey: Keys.enabled) }
    }

    // MARK: - Permission

    /// Asks for notification permission the first time only, then (if granted
    /// and enabled) schedules the daily reminder. Safe to call after every
    /// level completion — it no-ops once permission has been requested.
    func requestAuthorizationIfNeeded() async {
        guard !defaults.bool(forKey: Keys.asked) else {
            // Already asked before: just make sure the reminder is in sync.
            await refreshScheduling()
            return
        }
        defaults.set(true, forKey: Keys.asked)
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            if granted {
                await scheduleDailyReminder()
            }
        } catch {
            // Permission errors are non-fatal; the app works without reminders.
        }
    }

    // MARK: - Scheduling

    /// Replaces any existing reminder with a fresh daily one at `reminderHour`.
    /// Always clears the pending request first so we never stack duplicates.
    func scheduleDailyReminder() async {
        center.removePendingNotificationRequests(withIdentifiers: [dailyReminderID])

        guard isEnabled else { return }

        let content = UNMutableNotificationContent()
        content.title = "Your daily words are waiting!"
        content.body = "Keep your streak alive and learn new terms today."
        content.sound = .default

        var components = DateComponents()
        components.hour = reminderHour
        components.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

        let request = UNNotificationRequest(identifier: dailyReminderID,
                                            content: content,
                                            trigger: trigger)
        try? await center.add(request)
    }

    /// Cancels the pending daily reminder.
    func cancelDailyReminder() {
        center.removePendingNotificationRequests(withIdentifiers: [dailyReminderID])
    }

    /// Re-applies scheduling based on the current authorization + enabled state.
    private func refreshScheduling() async {
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .authorized ||
              settings.authorizationStatus == .provisional else { return }
        await scheduleDailyReminder()
    }

    // MARK: - Settings toggle

    /// Turns daily reminders on or off from Settings. When turning on, this
    /// also requests permission if it has never been asked.
    func setEnabled(_ enabled: Bool) async {
        isEnabled = enabled
        if enabled {
            let settings = await center.notificationSettings()
            switch settings.authorizationStatus {
            case .notDetermined:
                defaults.set(true, forKey: Keys.asked)
                let granted = (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
                if granted { await scheduleDailyReminder() }
            case .authorized, .provisional:
                await scheduleDailyReminder()
            default:
                break // Denied at the system level; nothing we can do here.
            }
        } else {
            cancelDailyReminder()
        }
    }
}
