import MacStateFoundation

enum AppTextKey {
    case appTitle
    case liveMacOSSystemMonitor
    case cpu
    case cpuCores
    case memory
    case disk
    case battery
    case sensors
    case network
    case alerts
    case trends
    case runningApps
    case architecturePrefix
    case cpuLabel
    case gpuLabel
    case batteryLabel
    case latest
    case average
    case peak
    case history
    case exportCSV
    case timeRange
    case live
    case day24Hours
    case liveHistorySubtitle
    case dayHistorySubtitle
    case cpuUsage
    case memoryUsage
    case networkThroughput
    case diskActivity
    case diskCapacity
    case batteryLevel
    case overallSystemCPUUtilization
    case residentMemoryPressureOverTime
    case combinedUploadAndDownloadThroughput
    case combinedReadAndWriteThroughput
    case usedCapacityPrimaryVolume
    case batteryPercentageWhenAvailable
    case exportFailed
    case unableExportHistoryCSV
    case ok
    case frontmost
    case visibleAppsAfterScan
    case refreshMetrics
    case openHistory
    case openSettings
    case settings
    case settingsSubtitle
    case general
    case generalSummary
    case launchAtLogin
    case refreshLaunchAtLoginStatus
    case menuBar
    case menuBarText
    case primaryMetric
    case secondaryMetric
    case selectedMetrics
    case preview
    case showDetails
    case hideDetails
    case alertWhenCPUUsageHigh
    case cpuThreshold
    case alertWhenMemoryUsageHigh
    case memoryThreshold
    case alertWhenBatteryLow
    case batteryThreshold
    case alertWhenDiskActivityHigh
    case diskThreshold
    case alertCooldown
    case alertsUseLocalNotifications
    case alertsSectionSummary
    case language
    case diagnostics
    case diagnosticsSummary
    case currentArchitecture
    case diskFootprint
    case diskActivityLabel
    case batteryLabelWithColon
    case thermalCondition
    case sensorSource
    case cpuTemperature
    case gpuTemperature
    case batteryTemperature
    case cooling
    case perCoreCPU
    case dashboardAppList
    case trendCache
    case lastUpdated
    case aboutApp
    case aboutSummary
    case appVersion
    case buildNumber
    case compatibility
    case openAboutPanel
    case hideApp
    case hideOthers
    case showAll
    case quitApp
    case upload
    case noVisibleApps
    case unavailable
    case yes
}

enum AppText {
    static func value(
        _ key: AppTextKey,
        language: AppLanguage
    ) -> String {
        switch (language.resolvedLanguage, key) {
        case (.system, let key):
            return value(key, language: .english)
        case (.simplifiedChinese, .appTitle):
            return "mac-state"
        case (.simplifiedChinese, .liveMacOSSystemMonitor):
            return "轻量级 macOS 状态监测"
        case (.simplifiedChinese, .cpu):
            return "CPU"
        case (.simplifiedChinese, .cpuCores):
            return "CPU 核心"
        case (.simplifiedChinese, .memory):
            return "内存"
        case (.simplifiedChinese, .disk):
            return "磁盘"
        case (.simplifiedChinese, .battery):
            return "电池"
        case (.simplifiedChinese, .sensors):
            return "传感器"
        case (.simplifiedChinese, .network):
            return "网络"
        case (.simplifiedChinese, .alerts):
            return "告警"
        case (.simplifiedChinese, .trends):
            return "趋势"
        case (.simplifiedChinese, .runningApps):
            return "运行中的应用"
        case (.simplifiedChinese, .architecturePrefix):
            return "架构"
        case (.simplifiedChinese, .cpuLabel):
            return "CPU"
        case (.simplifiedChinese, .gpuLabel):
            return "GPU"
        case (.simplifiedChinese, .batteryLabel):
            return "电池"
        case (.simplifiedChinese, .latest):
            return "最新"
        case (.simplifiedChinese, .average):
            return "平均"
        case (.simplifiedChinese, .peak):
            return "峰值"
        case (.simplifiedChinese, .history):
            return "历史"
        case (.simplifiedChinese, .exportCSV):
            return "导出 CSV"
        case (.simplifiedChinese, .timeRange):
            return "时间范围"
        case (.simplifiedChinese, .live):
            return "实时"
        case (.simplifiedChinese, .day24Hours):
            return "24 小时"
        case (.simplifiedChinese, .liveHistorySubtitle):
            return "展示当前监控会话中的原始样本。"
        case (.simplifiedChinese, .dayHistorySubtitle):
            return "展示最近 24 小时按分钟聚合后的历史样本。"
        case (.simplifiedChinese, .cpuUsage):
            return "CPU 使用率"
        case (.simplifiedChinese, .memoryUsage):
            return "内存使用率"
        case (.simplifiedChinese, .networkThroughput):
            return "网络吞吐"
        case (.simplifiedChinese, .diskActivity):
            return "磁盘活动"
        case (.simplifiedChinese, .diskCapacity):
            return "磁盘容量"
        case (.simplifiedChinese, .batteryLevel):
            return "电量"
        case (.simplifiedChinese, .overallSystemCPUUtilization):
            return "整体系统 CPU 利用率"
        case (.simplifiedChinese, .residentMemoryPressureOverTime):
            return "内存压力随时间变化"
        case (.simplifiedChinese, .combinedUploadAndDownloadThroughput):
            return "上传和下载的合计吞吐"
        case (.simplifiedChinese, .combinedReadAndWriteThroughput):
            return "读取和写入的合计吞吐"
        case (.simplifiedChinese, .usedCapacityPrimaryVolume):
            return "主磁盘已用容量占比"
        case (.simplifiedChinese, .batteryPercentageWhenAvailable):
            return "有电池指标时显示电量百分比"
        case (.simplifiedChinese, .exportFailed):
            return "导出失败"
        case (.simplifiedChinese, .unableExportHistoryCSV):
            return "无法将历史记录导出为 CSV。"
        case (.simplifiedChinese, .ok):
            return "好的"
        case (.simplifiedChinese, .frontmost):
            return "当前前台"
        case (.simplifiedChinese, .visibleAppsAfterScan):
            return "第一次进程扫描完成后，这里会显示可见应用。"
        case (.simplifiedChinese, .refreshMetrics):
            return "刷新指标"
        case (.simplifiedChinese, .openHistory):
            return "打开历史"
        case (.simplifiedChinese, .openSettings):
            return "打开设置"
        case (.simplifiedChinese, .settings):
            return "设置"
        case (.simplifiedChinese, .settingsSubtitle):
            return "调整启动方式、菜单栏展示、告警规则和应用信息。"
        case (.simplifiedChinese, .general):
            return "通用"
        case (.simplifiedChinese, .generalSummary):
            return "语言和基础应用行为。"
        case (.simplifiedChinese, .launchAtLogin):
            return "登录时启动 mac-state"
        case (.simplifiedChinese, .refreshLaunchAtLoginStatus):
            return "刷新登录启动状态"
        case (.simplifiedChinese, .menuBar):
            return "菜单栏"
        case (.simplifiedChinese, .menuBarText):
            return "菜单栏文本"
        case (.simplifiedChinese, .primaryMetric):
            return "主指标"
        case (.simplifiedChinese, .secondaryMetric):
            return "副指标"
        case (.simplifiedChinese, .selectedMetrics):
            return "已选指标"
        case (.simplifiedChinese, .preview):
            return "预览"
        case (.simplifiedChinese, .showDetails):
            return "展开详情"
        case (.simplifiedChinese, .hideDetails):
            return "收起详情"
        case (.simplifiedChinese, .alertWhenCPUUsageHigh):
            return "当 CPU 使用率过高时告警"
        case (.simplifiedChinese, .cpuThreshold):
            return "CPU 阈值"
        case (.simplifiedChinese, .alertWhenMemoryUsageHigh):
            return "当内存使用率过高时告警"
        case (.simplifiedChinese, .memoryThreshold):
            return "内存阈值"
        case (.simplifiedChinese, .alertWhenBatteryLow):
            return "当电池电量过低时告警"
        case (.simplifiedChinese, .batteryThreshold):
            return "电池阈值"
        case (.simplifiedChinese, .alertWhenDiskActivityHigh):
            return "当磁盘活动过高时告警"
        case (.simplifiedChinese, .diskThreshold):
            return "磁盘阈值"
        case (.simplifiedChinese, .alertCooldown):
            return "告警冷却时间"
        case (.simplifiedChinese, .alertsUseLocalNotifications):
            return "授予通知权限后，告警会通过本地通知发送。"
        case (.simplifiedChinese, .alertsSectionSummary):
            return "只开启你关心的告警，并调整对应阈值。"
        case (.simplifiedChinese, .language):
            return "语言"
        case (.simplifiedChinese, .diagnostics):
            return "诊断"
        case (.simplifiedChinese, .diagnosticsSummary):
            return "显示最近一次采样的关键状态，方便快速确认。"
        case (.simplifiedChinese, .currentArchitecture):
            return "当前架构"
        case (.simplifiedChinese, .diskFootprint):
            return "磁盘占用"
        case (.simplifiedChinese, .diskActivityLabel):
            return "磁盘活动"
        case (.simplifiedChinese, .batteryLabelWithColon):
            return "电池"
        case (.simplifiedChinese, .thermalCondition):
            return "热状态"
        case (.simplifiedChinese, .sensorSource):
            return "传感器来源"
        case (.simplifiedChinese, .cpuTemperature):
            return "CPU 温度"
        case (.simplifiedChinese, .gpuTemperature):
            return "GPU 温度"
        case (.simplifiedChinese, .batteryTemperature):
            return "电池温度"
        case (.simplifiedChinese, .cooling):
            return "散热"
        case (.simplifiedChinese, .perCoreCPU):
            return "每核心 CPU"
        case (.simplifiedChinese, .dashboardAppList):
            return "仪表盘应用列表"
        case (.simplifiedChinese, .trendCache):
            return "趋势缓存"
        case (.simplifiedChinese, .lastUpdated):
            return "最后更新"
        case (.simplifiedChinese, .aboutApp):
            return "关于 mac-state"
        case (.simplifiedChinese, .aboutSummary):
            return "面向 Intel 与 Apple Silicon 的原生开源 macOS 状态监测工具。"
        case (.simplifiedChinese, .appVersion):
            return "版本"
        case (.simplifiedChinese, .buildNumber):
            return "构建"
        case (.simplifiedChinese, .compatibility):
            return "兼容性"
        case (.simplifiedChinese, .openAboutPanel):
            return "打开 macOS 关于面板"
        case (.simplifiedChinese, .hideApp):
            return "隐藏 mac-state"
        case (.simplifiedChinese, .hideOthers):
            return "隐藏其他"
        case (.simplifiedChinese, .showAll):
            return "全部显示"
        case (.simplifiedChinese, .quitApp):
            return "退出 mac-state"
        case (.simplifiedChinese, .upload):
            return "上传"
        case (.simplifiedChinese, .noVisibleApps):
            return "没有可见应用"
        case (.simplifiedChinese, .unavailable):
            return "不可用"
        case (.simplifiedChinese, .yes):
            return "是"

        case (.english, .appTitle):
            return "mac-state"
        case (.english, .liveMacOSSystemMonitor):
            return "Live macOS system monitor"
        case (.english, .cpu):
            return "CPU"
        case (.english, .cpuCores):
            return "CPU Cores"
        case (.english, .memory):
            return "Memory"
        case (.english, .disk):
            return "Disk"
        case (.english, .battery):
            return "Battery"
        case (.english, .sensors):
            return "Sensors"
        case (.english, .network):
            return "Network"
        case (.english, .alerts):
            return "Alerts"
        case (.english, .trends):
            return "Trends"
        case (.english, .runningApps):
            return "Running Apps"
        case (.english, .architecturePrefix):
            return "Architecture"
        case (.english, .cpuLabel):
            return "CPU"
        case (.english, .gpuLabel):
            return "GPU"
        case (.english, .batteryLabel):
            return "Battery"
        case (.english, .latest):
            return "Latest"
        case (.english, .average):
            return "Average"
        case (.english, .peak):
            return "Peak"
        case (.english, .history):
            return "History"
        case (.english, .exportCSV):
            return "Export CSV"
        case (.english, .timeRange):
            return "Time Range"
        case (.english, .live):
            return "Live"
        case (.english, .day24Hours):
            return "24 Hours"
        case (.english, .liveHistorySubtitle):
            return "Recent raw samples captured during active monitoring"
        case (.english, .dayHistorySubtitle):
            return "Minute-level aggregates retained for the last 24 hours"
        case (.english, .cpuUsage):
            return "CPU Usage"
        case (.english, .memoryUsage):
            return "Memory Usage"
        case (.english, .networkThroughput):
            return "Network Throughput"
        case (.english, .diskActivity):
            return "Disk Activity"
        case (.english, .diskCapacity):
            return "Disk Capacity"
        case (.english, .batteryLevel):
            return "Battery Level"
        case (.english, .overallSystemCPUUtilization):
            return "Overall system CPU utilization"
        case (.english, .residentMemoryPressureOverTime):
            return "Resident memory pressure over time"
        case (.english, .combinedUploadAndDownloadThroughput):
            return "Combined upload and download throughput"
        case (.english, .combinedReadAndWriteThroughput):
            return "Combined read and write throughput"
        case (.english, .usedCapacityPrimaryVolume):
            return "Used capacity as a percentage of the primary volume"
        case (.english, .batteryPercentageWhenAvailable):
            return "Battery percentage when battery metrics are available"
        case (.english, .exportFailed):
            return "Export Failed"
        case (.english, .unableExportHistoryCSV):
            return "Unable to export history as CSV."
        case (.english, .ok):
            return "OK"
        case (.english, .frontmost):
            return "Frontmost"
        case (.english, .visibleAppsAfterScan):
            return "Visible apps will appear after the first process scan."
        case (.english, .refreshMetrics):
            return "Refresh Metrics"
        case (.english, .openHistory):
            return "Open History"
        case (.english, .openSettings):
            return "Open Settings"
        case (.english, .settings):
            return "Settings"
        case (.english, .settingsSubtitle):
            return "Adjust startup behavior, menu bar presentation, alerts, and app details."
        case (.english, .general):
            return "General"
        case (.english, .generalSummary):
            return "Language and basic application behavior."
        case (.english, .launchAtLogin):
            return "Launch mac-state at login"
        case (.english, .refreshLaunchAtLoginStatus):
            return "Refresh Launch at Login Status"
        case (.english, .menuBar):
            return "Menu Bar"
        case (.english, .menuBarText):
            return "Menu bar text"
        case (.english, .primaryMetric):
            return "Primary metric"
        case (.english, .secondaryMetric):
            return "Secondary metric"
        case (.english, .selectedMetrics):
            return "Selected metrics"
        case (.english, .preview):
            return "Preview"
        case (.english, .showDetails):
            return "Show details"
        case (.english, .hideDetails):
            return "Hide details"
        case (.english, .alertWhenCPUUsageHigh):
            return "Alert when CPU usage is high"
        case (.english, .cpuThreshold):
            return "CPU threshold"
        case (.english, .alertWhenMemoryUsageHigh):
            return "Alert when memory usage is high"
        case (.english, .memoryThreshold):
            return "Memory threshold"
        case (.english, .alertWhenBatteryLow):
            return "Alert when battery is low"
        case (.english, .batteryThreshold):
            return "Battery threshold"
        case (.english, .alertWhenDiskActivityHigh):
            return "Alert when disk activity is high"
        case (.english, .diskThreshold):
            return "Disk threshold"
        case (.english, .alertCooldown):
            return "Alert cooldown"
        case (.english, .alertsUseLocalNotifications):
            return "Alerts use local notifications after notification permission is granted."
        case (.english, .alertsSectionSummary):
            return "Enable only the alerts you care about and tune their thresholds."
        case (.english, .language):
            return "Language"
        case (.english, .diagnostics):
            return "Diagnostics"
        case (.english, .diagnosticsSummary):
            return "Latest sampled values for quick verification and troubleshooting."
        case (.english, .currentArchitecture):
            return "Current architecture"
        case (.english, .diskFootprint):
            return "Disk footprint"
        case (.english, .diskActivityLabel):
            return "Disk activity"
        case (.english, .batteryLabelWithColon):
            return "Battery"
        case (.english, .thermalCondition):
            return "Thermal condition"
        case (.english, .sensorSource):
            return "Sensor source"
        case (.english, .cpuTemperature):
            return "CPU temperature"
        case (.english, .gpuTemperature):
            return "GPU temperature"
        case (.english, .batteryTemperature):
            return "Battery temperature"
        case (.english, .cooling):
            return "Cooling"
        case (.english, .perCoreCPU):
            return "Per-core CPU"
        case (.english, .dashboardAppList):
            return "Dashboard app list"
        case (.english, .trendCache):
            return "Trend cache"
        case (.english, .lastUpdated):
            return "Last updated"
        case (.english, .aboutApp):
            return "About mac-state"
        case (.english, .aboutSummary):
            return "Open-source native macOS monitor built for Intel and Apple Silicon."
        case (.english, .appVersion):
            return "Version"
        case (.english, .buildNumber):
            return "Build"
        case (.english, .compatibility):
            return "Compatibility"
        case (.english, .openAboutPanel):
            return "Open macOS About Panel"
        case (.english, .hideApp):
            return "Hide mac-state"
        case (.english, .hideOthers):
            return "Hide Others"
        case (.english, .showAll):
            return "Show All"
        case (.english, .quitApp):
            return "Quit mac-state"
        case (.english, .upload):
            return "Upload"
        case (.english, .noVisibleApps):
            return "No visible apps"
        case (.english, .unavailable):
            return "Unavailable"
        case (.english, .yes):
            return "Yes"
        }
    }
}
