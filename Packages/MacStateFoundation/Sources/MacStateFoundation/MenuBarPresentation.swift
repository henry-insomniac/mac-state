import Foundation

public enum MenuBarTextMode: String, CaseIterable, Codable, Sendable, Equatable {
    case selectedMetric
    case appName
    case iconOnly

    public var title: String {
        switch self {
        case .selectedMetric:
            "Selected Metric"
        case .appName:
            "App Name"
        case .iconOnly:
            "Icon Only"
        }
    }
}

public enum MenuBarPrimaryMetric: String, CaseIterable, Codable, Sendable, Equatable {
    case cpuUsage
    case memoryUsage
    case networkDownload
    case networkUpload
    case diskActivity
    case batteryLevel

    public var title: String {
        switch self {
        case .cpuUsage:
            "CPU Usage"
        case .memoryUsage:
            "Memory Usage"
        case .networkDownload:
            "Network Download"
        case .networkUpload:
            "Network Upload"
        case .diskActivity:
            "Disk Activity"
        case .batteryLevel:
            "Battery Level"
        }
    }

    public var symbolName: String {
        switch self {
        case .cpuUsage:
            "speedometer"
        case .memoryUsage:
            "square.stack.3d.up"
        case .networkDownload:
            "arrow.down.circle"
        case .networkUpload:
            "arrow.up.circle"
        case .diskActivity:
            "externaldrive"
        case .batteryLevel:
            "battery.100"
        }
    }
}

public struct MenuBarPresentation: Codable, Sendable, Equatable {
    public var textMode: MenuBarTextMode
    public var primaryMetric: MenuBarPrimaryMetric

    public init(
        textMode: MenuBarTextMode,
        primaryMetric: MenuBarPrimaryMetric
    ) {
        self.textMode = textMode
        self.primaryMetric = primaryMetric
    }

    public static let `default` = MenuBarPresentation(
        textMode: .selectedMetric,
        primaryMetric: .cpuUsage
    )
}
