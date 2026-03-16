import Foundation

public enum SupportedArchitecture: String, CaseIterable, Sendable {
    case appleSilicon = "arm64"
    case intel = "x86_64"
}

public struct PlatformCapabilities: Sendable, Equatable {
    public static let minimumSupportedMacOSVersion = 11

    public let architecture: SupportedArchitecture
    public let supportsWidgets: Bool
    public let supportsModernLoginItems: Bool

    public init(
        architecture: SupportedArchitecture,
        supportsWidgets: Bool,
        supportsModernLoginItems: Bool
    ) {
        self.architecture = architecture
        self.supportsWidgets = supportsWidgets
        self.supportsModernLoginItems = supportsModernLoginItems
    }
}

public extension PlatformCapabilities {
    static var current: PlatformCapabilities {
        PlatformCapabilities(
            architecture: currentArchitecture,
            supportsWidgets: true,
            supportsModernLoginItems: ProcessInfo.processInfo.operatingSystemVersion.majorVersion >= 13
        )
    }

    static var currentArchitecture: SupportedArchitecture {
        #if arch(arm64)
        .appleSilicon
        #else
        .intel
        #endif
    }
}
