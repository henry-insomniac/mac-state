import Foundation
import MacStateMetrics
import UserNotifications

actor AlertNotificationService {
    private enum AuthorizationState: Sendable {
        case notDetermined
        case authorized
        case denied
    }

    private let notificationCenter: UNUserNotificationCenter
    private var lastDeliveredAt: [MetricAlertType: Date] = [:]

    init(notificationCenter: UNUserNotificationCenter = .current()) {
        self.notificationCenter = notificationCenter
    }

    func requestAuthorizationIfNeeded() async {
        let authorizationState = await authorizationState()
        guard authorizationState == .notDetermined else {
            return
        }

        _ = try? await requestAuthorization(options: [.alert, .sound])
    }

    func deliver(
        alerts: [MetricAlert],
        cooldownMinutes: Int
    ) async {
        guard alerts.isEmpty == false else {
            return
        }

        let authorizationState = await authorizationState()
        guard authorizationState == .authorized else {
            return
        }

        let now = Date()
        let cooldownSeconds = TimeInterval(max(cooldownMinutes, 1) * 60)

        for alert in alerts {
            if let lastDeliveredAt = lastDeliveredAt[alert.type],
               now.timeIntervalSince(lastDeliveredAt) < cooldownSeconds {
                continue
            }

            let content = UNMutableNotificationContent()
            content.title = alert.title
            content.body = alert.body
            content.sound = .default

            let request = UNNotificationRequest(
                identifier: "mac-state.\(alert.type.rawValue).\(Int(now.timeIntervalSince1970))",
                content: content,
                trigger: nil
            )

            do {
                try await add(request)
                self.lastDeliveredAt[alert.type] = now
            } catch {
                continue
            }
        }
    }

    private func authorizationState() async -> AuthorizationState {
        await withCheckedContinuation { continuation in
            notificationCenter.getNotificationSettings { settings in
                switch settings.authorizationStatus {
                case .notDetermined:
                    continuation.resume(returning: .notDetermined)
                case .authorized:
                    continuation.resume(returning: .authorized)
                default:
                    continuation.resume(returning: .denied)
                }
            }
        }
    }

    private func requestAuthorization(
        options: UNAuthorizationOptions
    ) async throws -> Bool {
        try await withCheckedThrowingContinuation { continuation in
            notificationCenter.requestAuthorization(options: options) { granted, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                continuation.resume(returning: granted)
            }
        }
    }

    private func add(_ request: UNNotificationRequest) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            notificationCenter.add(request) { error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                continuation.resume(returning: ())
            }
        }
    }
}
