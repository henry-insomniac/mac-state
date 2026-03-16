import Foundation

public enum MenuBarTextMode: String, Codable, Sendable, Equatable {
    case selectedMetric
    case twoMetrics
    case selectedMetrics
    case appName
    case iconOnly

    public static var allCases: [Self] {
        [
            .selectedMetric,
            .selectedMetrics,
            .appName,
            .iconOnly,
        ]
    }

    public var normalized: Self {
        switch self {
        case .twoMetrics:
            return .selectedMetrics
        case .selectedMetric, .selectedMetrics, .appName, .iconOnly:
            return self
        }
    }

    public func localizedTitle(language: AppLanguage) -> String {
        switch (language.resolvedLanguage, normalized) {
        case (.system, .selectedMetric):
            return "Selected Metric"
        case (.system, .twoMetrics), (.system, .selectedMetrics):
            return "Multiple Metrics"
        case (.system, .appName):
            return "App Name"
        case (.system, .iconOnly):
            return "Icon Only"
        case (.simplifiedChinese, .selectedMetric):
            return "所选指标"
        case (.simplifiedChinese, .twoMetrics), (.simplifiedChinese, .selectedMetrics):
            return "多指标"
        case (.simplifiedChinese, .appName):
            return "应用名称"
        case (.simplifiedChinese, .iconOnly):
            return "仅图标"
        case (.english, .selectedMetric):
            return "Selected Metric"
        case (.english, .twoMetrics), (.english, .selectedMetrics):
            return "Multiple Metrics"
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
    case networkThroughput
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
        case (.system, .networkThroughput):
            return "Network Throughput"
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
        case (.simplifiedChinese, .networkThroughput):
            return "网络双向速率"
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
        case (.english, .networkThroughput):
            return "Network Throughput"
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
        case (.system, .networkThroughput), (.english, .networkThroughput):
            return "NET"
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
        case (.simplifiedChinese, .networkThroughput):
            return "网络"
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
        case .networkThroughput:
            "arrow.up.arrow.down.circle"
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
    public var tertiaryMetric: MenuBarPrimaryMetric?
    public var selectedMetrics: [MenuBarPrimaryMetric]?

    public init(
        textMode: MenuBarTextMode,
        primaryMetric: MenuBarPrimaryMetric,
        secondaryMetric: MenuBarPrimaryMetric? = nil,
        tertiaryMetric: MenuBarPrimaryMetric? = nil,
        selectedMetrics: [MenuBarPrimaryMetric]? = nil
    ) {
        self.textMode = textMode.normalized
        self.primaryMetric = primaryMetric
        self.secondaryMetric = secondaryMetric
        self.tertiaryMetric = tertiaryMetric
        self.selectedMetrics = selectedMetrics
    }

    public static let `default` = MenuBarPresentation(
        textMode: .selectedMetrics,
        primaryMetric: .cpuUsage,
        secondaryMetric: .memoryUsage,
        tertiaryMetric: .networkDownload,
        selectedMetrics: [.cpuUsage, .memoryUsage, .networkDownload]
    )
}
