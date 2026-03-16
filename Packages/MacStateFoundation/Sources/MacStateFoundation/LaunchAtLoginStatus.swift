import Foundation

public enum LaunchAtLoginAvailability: String, Sendable, Equatable {
    case supported
    case requiresLegacyHelper
}

public enum LaunchAtLoginRegistrationState: String, Sendable, Equatable {
    case disabled
    case enabled
    case requiresApproval
}

public struct LaunchAtLoginStatus: Sendable, Equatable {
    public let availability: LaunchAtLoginAvailability
    public let registrationState: LaunchAtLoginRegistrationState

    public init(
        availability: LaunchAtLoginAvailability,
        registrationState: LaunchAtLoginRegistrationState
    ) {
        self.availability = availability
        self.registrationState = registrationState
    }

    public var canToggle: Bool {
        availability == .supported
    }

    public var isEnabled: Bool {
        registrationState != .disabled
    }

    public var requiresApproval: Bool {
        registrationState == .requiresApproval
    }

    public static let legacyHelperRequired = LaunchAtLoginStatus(
        availability: .requiresLegacyHelper,
        registrationState: .disabled
    )
}
