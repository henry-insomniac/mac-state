import Foundation

public enum AppLanguage: String, CaseIterable, Codable, Sendable, Equatable {
    case system
    case english
    case simplifiedChinese

    public var resolvedLanguage: AppLanguage {
        switch self {
        case .system:
            let preferredIdentifier = Locale.preferredLanguages.first ?? Locale.current.identifier
            let normalizedIdentifier = preferredIdentifier.lowercased()

            if normalizedIdentifier.contains("zh") {
                return .simplifiedChinese
            }

            return .english
        case .english, .simplifiedChinese:
            return self
        }
    }

    public func displayName(in presentationLanguage: AppLanguage) -> String {
        switch (presentationLanguage.resolvedLanguage, self) {
        case (.system, .system):
            return "System"
        case (.system, .english):
            return "English"
        case (.system, .simplifiedChinese):
            return "Simplified Chinese"
        case (.simplifiedChinese, .system):
            return "跟随系统"
        case (.simplifiedChinese, .english):
            return "English"
        case (.simplifiedChinese, .simplifiedChinese):
            return "简体中文"
        case (.english, .system):
            return "System"
        case (.english, .english):
            return "English"
        case (.english, .simplifiedChinese):
            return "Simplified Chinese"
        }
    }
}

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
