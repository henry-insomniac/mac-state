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
    private let legacyHelperBundleIdentifier: String?

    public init(legacyHelperBundleIdentifier: String? = nil) {
        self.legacyHelperBundleIdentifier = legacyHelperBundleIdentifier
    }

    public func status() -> LaunchAtLoginStatus {
        if #available(macOS 13.0, *) {
            return status(for: SMAppService.mainApp.status)
        }

        return legacyStatus()
    }

    public func setEnabled(_ enabled: Bool) throws -> LaunchAtLoginStatus {
        if #available(macOS 13.0, *) {
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

        guard let legacyHelperBundleIdentifier else {
            throw LaunchAtLoginError.legacyHelperRequired
        }

        let didApplyChange = SMLoginItemSetEnabled(legacyHelperBundleIdentifier as CFString, enabled)
        guard didApplyChange else {
            let message = "ServiceManagement rejected the legacy login item update."
            if enabled {
                throw LaunchAtLoginError.registrationFailed(message)
            }

            throw LaunchAtLoginError.unregistrationFailed(message)
        }

        return legacyStatus()
    }

    private func legacyStatus() -> LaunchAtLoginStatus {
        guard let legacyHelperBundleIdentifier else {
            return .legacyHelperRequired
        }

        let jobDictionaries = legacyJobDictionaries()
        let isRegistered = jobDictionaries.contains { dictionary in
            (dictionary["Label"] as? String) == legacyHelperBundleIdentifier
        }

        return LaunchAtLoginStatus(
            availability: .supported,
            registrationState: isRegistered ? .enabled : .disabled
        )
    }

    private func legacyJobDictionaries() -> [[String: Any]] {
        guard let dictionaries = SMCopyAllJobDictionaries(kSMDomainUserLaunchd) else {
            return []
        }

        let bridgedDictionaries = dictionaries.takeRetainedValue() as NSArray
        return bridgedDictionaries.compactMap { $0 as? [String: Any] }
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
