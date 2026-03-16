import Foundation
import ServiceManagement

@MainActor
public protocol LaunchAtLoginService: Sendable {
    func status() -> LaunchAtLoginStatus
    func setEnabled(_ enabled: Bool) throws -> LaunchAtLoginStatus
}

public enum LaunchAtLoginError: LocalizedError, Sendable, Equatable {
    case legacyHelperRequired
    case registrationFailed(String)
    case unregistrationFailed(String)

    public var errorDescription: String? {
        switch self {
        case .legacyHelperRequired:
            return "Launch at login on macOS 11 and 12 requires the bundled login helper target."
        case let .registrationFailed(message):
            return "Unable to enable launch at login: \(message)"
        case let .unregistrationFailed(message):
            return "Unable to disable launch at login: \(message)"
        }
    }
}

@MainActor
public final class SystemLaunchAtLoginService: LaunchAtLoginService {
    public init() {}

    public func status() -> LaunchAtLoginStatus {
        guard #available(macOS 13.0, *) else {
            return .legacyHelperRequired
        }

        return status(for: SMAppService.mainApp.status)
    }

    public func setEnabled(_ enabled: Bool) throws -> LaunchAtLoginStatus {
        guard #available(macOS 13.0, *) else {
            throw LaunchAtLoginError.legacyHelperRequired
        }

        let service = SMAppService.mainApp
        let currentStatus = status(for: service.status)

        if enabled == currentStatus.isEnabled,
           currentStatus.requiresApproval == false {
            return currentStatus
        }

        do {
            if enabled {
                try service.register()
            } else {
                try service.unregister()
            }
        } catch {
            let message = (error as NSError).localizedDescription

            if enabled {
                throw LaunchAtLoginError.registrationFailed(message)
            }

            throw LaunchAtLoginError.unregistrationFailed(message)
        }

        return status(for: service.status)
    }

    @available(macOS 13.0, *)
    private func status(for status: SMAppService.Status) -> LaunchAtLoginStatus {
        switch status {
        case .enabled:
            LaunchAtLoginStatus(
                availability: .supported,
                registrationState: .enabled
            )
        case .requiresApproval:
            LaunchAtLoginStatus(
                availability: .supported,
                registrationState: .requiresApproval
            )
        case .notRegistered:
            LaunchAtLoginStatus(
                availability: .supported,
                registrationState: .disabled
            )
        case .notFound:
            LaunchAtLoginStatus(
                availability: .supported,
                registrationState: .disabled
            )
        @unknown default:
            LaunchAtLoginStatus(
                availability: .supported,
                registrationState: .disabled
            )
        }
    }
}
