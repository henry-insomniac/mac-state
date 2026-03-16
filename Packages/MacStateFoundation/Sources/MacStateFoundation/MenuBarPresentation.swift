import Foundation

public enum MenuBarTextMode: String, CaseIterable, Codable, Sendable, Equatable {
    case selectedMetric
    case twoMetrics
    case appName
    case iconOnly

    public func localizedTitle(language: AppLanguage) -> String {
        switch (language.resolvedLanguage, self) {
        case (.system, .selectedMetric):
            return "Selected Metric"
        case (.system, .twoMetrics):
            return "Two Metrics"
        case (.system, .appName):
            return "App Name"
        case (.system, .iconOnly):
            return "Icon Only"
        case (.simplifiedChinese, .selectedMetric):
            return "所选指标"
        case (.simplifiedChinese, .twoMetrics):
            return "双指标"
        case (.simplifiedChinese, .appName):
            return "应用名称"
        case (.simplifiedChinese, .iconOnly):
            return "仅图标"
        case (.english, .selectedMetric):
            return "Selected Metric"
        case (.english, .twoMetrics):
            return "Two Metrics"
        case (.english, .appName):
            return "App Name"
        case (.english, .iconOnly):
            return "Icon Only"
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

    public func localizedTitle(language: AppLanguage) -> String {
        switch (language.resolvedLanguage, self) {
        case (.system, .cpuUsage):
            return "CPU Usage"
        case (.system, .memoryUsage):
            return "Memory Usage"
        case (.system, .networkDownload):
            return "Network Download"
        case (.system, .networkUpload):
            return "Network Upload"
        case (.system, .diskActivity):
            return "Disk Activity"
        case (.system, .batteryLevel):
            return "Battery Level"
        case (.simplifiedChinese, .cpuUsage):
            return "CPU 使用率"
        case (.simplifiedChinese, .memoryUsage):
            return "内存使用率"
        case (.simplifiedChinese, .networkDownload):
            return "网络下载"
        case (.simplifiedChinese, .networkUpload):
            return "网络上传"
        case (.simplifiedChinese, .diskActivity):
            return "磁盘活动"
        case (.simplifiedChinese, .batteryLevel):
            return "电池电量"
        case (.english, .cpuUsage):
            return "CPU Usage"
        case (.english, .memoryUsage):
            return "Memory Usage"
        case (.english, .networkDownload):
            return "Network Download"
        case (.english, .networkUpload):
            return "Network Upload"
        case (.english, .diskActivity):
            return "Disk Activity"
        case (.english, .batteryLevel):
            return "Battery Level"
        }
    }

    public func localizedCompactTitle(language: AppLanguage) -> String {
        switch (language.resolvedLanguage, self) {
        case (.system, .cpuUsage), (.english, .cpuUsage):
            return "CPU"
        case (.system, .memoryUsage), (.english, .memoryUsage):
            return "MEM"
        case (.system, .networkDownload), (.english, .networkDownload):
            return "DOWN"
        case (.system, .networkUpload), (.english, .networkUpload):
            return "UP"
        case (.system, .diskActivity), (.english, .diskActivity):
            return "DISK"
        case (.system, .batteryLevel), (.english, .batteryLevel):
            return "BAT"
        case (.simplifiedChinese, .cpuUsage):
            return "CPU"
        case (.simplifiedChinese, .memoryUsage):
            return "内存"
        case (.simplifiedChinese, .networkDownload):
            return "下载"
        case (.simplifiedChinese, .networkUpload):
            return "上传"
        case (.simplifiedChinese, .diskActivity):
            return "磁盘"
        case (.simplifiedChinese, .batteryLevel):
            return "电池"
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
    public var secondaryMetric: MenuBarPrimaryMetric?

    public init(
        textMode: MenuBarTextMode,
        primaryMetric: MenuBarPrimaryMetric,
        secondaryMetric: MenuBarPrimaryMetric? = nil
    ) {
        self.textMode = textMode
        self.primaryMetric = primaryMetric
        self.secondaryMetric = secondaryMetric
    }

    public static let `default` = MenuBarPresentation(
        textMode: .twoMetrics,
        primaryMetric: .cpuUsage,
        secondaryMetric: .memoryUsage
    )
}
