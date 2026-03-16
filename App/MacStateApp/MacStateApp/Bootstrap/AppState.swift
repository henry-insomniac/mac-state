import Foundation
import Combine
import MacStateFoundation
import MacStateMetrics
import MacStateStorage

@MainActor
final class AppState: ObservableObject {
    struct RecentAlert: Identifiable, Equatable {
        let type: MetricAlertType
        let title: String
        let body: String
        let timestamp: Date

        var id: String {
            "\(type.rawValue)-\(timestamp.timeIntervalSince1970)"
        }
    }

    @Published private(set) var menuBarPresentation = MenuBarPresentation.default
    @Published private(set) var dashboardPresentation = DashboardPresentation.default
    @Published private(set) var appLanguage: AppLanguage = .system
    @Published private(set) var alertConfiguration = MetricAlertConfiguration()
    @Published private(set) var launchAtLoginStatus = LaunchAtLoginStatus(
        availability: PlatformCapabilities.current.supportsModernLoginItems ? .supported : .requiresLegacyHelper,
        registrationState: .disabled
    )
    @Published private(set) var cpuUsage = 0.0
    @Published private(set) var cpuCores: [CPUCoreSnapshot] = []
    @Published private(set) var memoryUsage = 0.0
    @Published private(set) var memoryUsedBytes: UInt64 = 0
    @Published private(set) var memoryTotalBytes: UInt64 = 0
    @Published private(set) var diskUsedBytes: UInt64 = 0
    @Published private(set) var diskFreeBytes: UInt64 = 0
    @Published private(set) var diskTotalBytes: UInt64 = 0
    @Published private(set) var diskReadBytesPerSecond: UInt64 = 0
    @Published private(set) var diskWriteBytesPerSecond: UInt64 = 0
    @Published private(set) var networkDownloadBytesPerSecond: UInt64 = 0
    @Published private(set) var networkUploadBytesPerSecond: UInt64 = 0
    @Published private(set) var activeNetworkInterfaces = 0
    @Published private(set) var batterySnapshot: BatterySnapshot?
    @Published private(set) var sensors = SensorSnapshot(
        thermalCondition: .nominal,
        source: .collecting,
        cpuTemperatureCelsius: nil,
        gpuTemperatureCelsius: nil,
        batteryTemperatureCelsius: nil,
        fans: []
    )
    @Published private(set) var processes: [ProcessSnapshot] = []
    @Published private(set) var historySamples: [MetricHistorySample] = []
    @Published private(set) var dayHistorySamples: [MetricHistorySample] = []
    @Published private(set) var recentAlerts: [RecentAlert] = []
    @Published private(set) var platformSummary = "Detecting..."
    @Published private(set) var lastUpdatedAt = Date()
    @Published private(set) var launchAtLoginErrorMessage: String?
    @Published private(set) var errorMessage: String?

    private let launchAtLoginService: any LaunchAtLoginService
    private let settingsStore: SettingsStore
    private let historyStore: MetricHistoryStore
    private var activeAlertTypes: Set<MetricAlertType> = []

    init(
        launchAtLoginService: any LaunchAtLoginService,
        settingsStore: SettingsStore = SettingsStore(),
        historyStore: MetricHistoryStore = MetricHistoryStore()
    ) {
        self.launchAtLoginService = launchAtLoginService
        self.settingsStore = settingsStore
        self.historyStore = historyStore
    }

    var resolvedLanguage: AppLanguage {
        appLanguage.resolvedLanguage
    }

    func text(_ key: AppTextKey) -> String {
        AppText.value(key, language: appLanguage)
    }

    func languageDisplayName(_ language: AppLanguage) -> String {
        language.displayName(in: appLanguage)
    }

    func menuBarTextModeTitle(_ value: MenuBarTextMode) -> String {
        value.localizedTitle(language: appLanguage)
    }

    func menuBarPrimaryMetricTitle(_ value: MenuBarPrimaryMetric) -> String {
        value.localizedTitle(language: appLanguage)
    }

    func menuBarPrimaryMetricCompactTitle(_ value: MenuBarPrimaryMetric) -> String {
        value.localizedCompactTitle(language: appLanguage)
    }

    var menuBarSelectedMetrics: [MenuBarPrimaryMetric] {
        resolvedMenuBarMetrics(for: menuBarPresentation)
    }

    var dashboardModules: [DashboardModuleConfiguration] {
        dashboardPresentation.orderedModules
    }

    var visibleDashboardModules: [DashboardModuleType] {
        dashboardModules
            .filter(\.isVisible)
            .map(\.type)
    }

    var dashboardConfigurationSummaryText: String {
        let visibleCount = dashboardModules.filter(\.isVisible).count
        let totalCount = dashboardModules.count

        switch resolvedLanguage {
        case .simplifiedChinese:
            return "当前显示 \(visibleCount) / \(totalCount) 个模块。"
        case .english, .system:
            return "Showing \(visibleCount) of \(totalCount) modules."
        }
    }

    var menuBarSelectedMetricsDetailText: String {
        let selectionCount = menuBarSelectedMetrics.count

        switch resolvedLanguage {
        case .simplifiedChinese:
            return "已选 \(selectionCount) 项。排在最前的指标会决定菜单栏图标。"
        case .english, .system:
            return "\(selectionCount) selected. The first metric controls the menu bar icon."
        }
    }

    func dashboardModuleTitle(_ module: DashboardModuleType) -> String {
        switch module {
        case .battery:
            text(.battery)
        case .network:
            text(.network)
        case .cpu:
            text(.cpu)
        case .cpuCores:
            text(.cpuCores)
        case .memory:
            text(.memory)
        case .disk:
            text(.disk)
        case .sensors:
            text(.sensors)
        case .alerts:
            text(.alerts)
        case .trends:
            text(.trends)
        case .runningApps:
            text(.runningApps)
        }
    }

    func dashboardModuleSummary(_ module: DashboardModuleType) -> String {
        switch module {
        case .battery:
            batteryDetailText
        case .network:
            combinedNetworkRateText
        case .cpu:
            cpuUsageText
        case .cpuCores:
            cpuCoreCountText
        case .memory:
            memoryFootprintText
        case .disk:
            diskActivityText
        case .sensors:
            thermalConditionText
        case .alerts:
            alertsStatusText
        case .trends:
            historySummaryText
        case .runningApps:
            runningAppsText
        }
    }

    func isDashboardModuleVisible(_ module: DashboardModuleType) -> Bool {
        dashboardPresentation.configuration(for: module).isVisible
    }

    func isDashboardModuleExpandedByDefault(_ module: DashboardModuleType) -> Bool {
        dashboardPresentation.configuration(for: module).isExpandedByDefault
    }

    func canMoveDashboardModuleUp(_ module: DashboardModuleType) -> Bool {
        guard let index = dashboardModules.firstIndex(where: { $0.type == module }) else {
            return false
        }

        return index > 0
    }

    func canMoveDashboardModuleDown(_ module: DashboardModuleType) -> Bool {
        guard let index = dashboardModules.firstIndex(where: { $0.type == module }) else {
            return false
        }

        return index < dashboardModules.count - 1
    }

    func isMenuBarMetricSelected(_ value: MenuBarPrimaryMetric) -> Bool {
        menuBarSelectedMetrics.contains(value)
    }

    func canSelectMenuBarMetric(_ value: MenuBarPrimaryMetric) -> Bool {
        _ = value
        return true
    }

    func menuBarMetricSelectionOrderText(for value: MenuBarPrimaryMetric) -> String? {
        guard let index = menuBarSelectedMetrics.firstIndex(of: value) else {
            return nil
        }

        return "\(index + 1)"
    }

    var menuBarTitle: String {
        switch menuBarPresentation.textMode.normalized {
        case .iconOnly:
            return ""
        case .appName:
            return text(.appTitle)
        case .selectedMetric:
            return menuBarMetricText(for: menuBarPresentation.primaryMetric)
        case .selectedMetrics:
            return menuBarSelectedMetrics.map { metric in
                "\(menuBarPrimaryMetricCompactTitle(metric)) \(menuBarMetricText(for: metric))"
            }.joined(separator: " · ")
        case .twoMetrics:
            return ""
        }
    }

    var menuBarSymbolName: String {
        menuBarSelectedMetrics.first?.symbolName ?? menuBarPresentation.primaryMetric.symbolName
    }

    var menuBarAccessibilityLabel: String {
        let primaryMetricTitle = menuBarPrimaryMetricTitle(menuBarPresentation.primaryMetric)
        let primaryMetricText = menuBarMetricText(for: menuBarPresentation.primaryMetric)

        if menuBarPresentation.textMode.normalized == .appName {
            return "\(text(.appTitle)), \(primaryMetricTitle) \(primaryMetricText)"
        }

        if menuBarPresentation.textMode.normalized == .iconOnly {
            return "\(primaryMetricTitle) \(primaryMetricText)"
        }

        if menuBarPresentation.textMode.normalized == .selectedMetrics {
            let components = menuBarSelectedMetrics.map { metric in
                "\(menuBarPrimaryMetricTitle(metric)) \(menuBarMetricText(for: metric))"
            }
            return "\(text(.appTitle)), \(components.joined(separator: ", "))"
        }

        return "\(text(.appTitle)) \(primaryMetricText)"
    }

    var menuBarSettingsSummaryText: String {
        switch menuBarPresentation.textMode.normalized {
        case .selectedMetric:
            switch resolvedLanguage {
            case .simplifiedChinese:
                return "菜单栏会实时显示\(menuBarPrimaryMetricTitle(menuBarPresentation.primaryMetric))。"
            case .english, .system:
                return "The menu bar shows \(menuBarPrimaryMetricTitle(menuBarPresentation.primaryMetric).lowercased()) as live text."
            }
        case .selectedMetrics:
            let selectedMetrics = localizedMenuBarMetricList(from: menuBarSelectedMetrics)
            switch resolvedLanguage {
            case .simplifiedChinese:
                return "菜单栏会同时显示\(selectedMetrics)。"
            case .english, .system:
                return "The menu bar can show multiple live metrics together. Current selection: \(selectedMetrics)."
            }
        case .appName:
            switch resolvedLanguage {
            case .simplifiedChinese:
                return "菜单栏会显示应用名称，并保留指标图标用于快速识别。"
            case .english, .system:
                return "The menu bar keeps the app name visible and uses the metric icon for quick context."
            }
        case .iconOnly:
            switch resolvedLanguage {
            case .simplifiedChinese:
                return "菜单栏保持仅图标显示，同时保留当前指标供以后切回文本模式。"
            case .english, .system:
                return "The menu bar stays icon-only and keeps the selected metric ready for future text mode."
            }
        case .twoMetrics:
            return ""
        }
    }

    var menuBarPreviewText: String {
        switch menuBarPresentation.textMode.normalized {
        case .selectedMetric:
            return menuBarMetricText(for: menuBarPresentation.primaryMetric)
        case .selectedMetrics:
            return menuBarTitle
        case .appName:
            return text(.appTitle)
        case .iconOnly:
            return menuBarTextModeTitle(.iconOnly)
        case .twoMetrics:
            return ""
        }
    }

    var cpuUsageText: String {
        percentageString(from: cpuUsage)
    }

    var menuBarMetricTitle: String {
        if menuBarPresentation.textMode.normalized == .selectedMetrics {
            return menuBarSelectedMetrics
                .map(menuBarPrimaryMetricTitle)
                .joined(separator: " · ")
        }

        return menuBarPrimaryMetricTitle(menuBarPresentation.primaryMetric)
    }

    var alertsSummaryText: String {
        if alertConfiguration.hasEnabledRules == false {
            return resolvedLanguage == .simplifiedChinese ? "所有告警均已关闭" : "All alerts are disabled"
        }

        switch resolvedLanguage {
        case .simplifiedChinese:
            return "冷却时间 \(alertConfiguration.clampedCooldownMinutes) 分钟"
        case .english, .system:
            return "Cooldown \(alertConfiguration.clampedCooldownMinutes)m"
        }
    }

    var launchAtLoginSummaryText: String {
        switch launchAtLoginStatus.availability {
        case .requiresLegacyHelper:
            return resolvedLanguage == .simplifiedChinese
                ? "在 macOS 11 和 12 上，登录启动需要 legacy helper 路径"
                : "Launch at login needs the legacy helper path on macOS 11 and 12"
        case .supported:
            switch launchAtLoginStatus.registrationState {
            case .disabled:
                return resolvedLanguage == .simplifiedChinese
                    ? "在你启用登录启动之前，mac-state 会保持手动启动"
                    : "mac-state will stay manual until you enable launch at login"
            case .enabled:
                return resolvedLanguage == .simplifiedChinese
                    ? "登录后 mac-state 会自动启动"
                    : "mac-state will launch automatically after you sign in"
            case .requiresApproval:
                return resolvedLanguage == .simplifiedChinese
                    ? "登录启动正在等待系统设置中的批准"
                    : "Launch at login is waiting for approval in System Settings"
            }
        }
    }

    var launchAtLoginDetailText: String {
        switch launchAtLoginStatus.availability {
        case .requiresLegacyHelper:
            return resolvedLanguage == .simplifiedChinese
                ? "macOS 11 和 12 需要 legacy 登录辅助程序，但当前构建中不可用。"
                : "The legacy login helper is required on macOS 11 and 12, but it is not available in the current build."
        case .supported:
            if PlatformCapabilities.current.supportsModernLoginItems == false {
                return resolvedLanguage == .simplifiedChinese
                    ? "macOS 11 和 12 使用打包在 Contents/Library/LoginItems 中的登录辅助程序。"
                    : "macOS 11 and 12 use the bundled login helper app inside Contents/Library/LoginItems."
            }

            if launchAtLoginStatus.requiresApproval {
                return resolvedLanguage == .simplifiedChinese
                    ? "请在 系统设置 > 通用 > 登录项 中批准 mac-state，然后回到这里刷新状态。"
                    : "Approve mac-state in System Settings > General > Login Items, then refresh the status here."
            }

            return resolvedLanguage == .simplifiedChinese
                ? "macOS 13+ 使用 ServiceManagement 直接注册主应用，无需单独的登录辅助程序。"
                : "macOS 13+ uses ServiceManagement to register the main app without a separate login helper."
        }
    }

    var alertsStatusText: String {
        if alertConfiguration.hasEnabledRules == false {
            return resolvedLanguage == .simplifiedChinese
                ? "至少启用一条规则后才能接收告警"
                : "Enable at least one rule to receive alerts"
        }

        if activeAlertTypes.isEmpty {
            return resolvedLanguage == .simplifiedChinese
                ? "当前没有活跃的告警条件"
                : "No alert conditions are currently active"
        }

        if activeAlertTypes.count == 1 {
            return resolvedLanguage == .simplifiedChinese
                ? "当前有 1 个活跃的告警条件"
                : "1 alert condition is currently active"
        }

        return resolvedLanguage == .simplifiedChinese
            ? "当前有 \(activeAlertTypes.count) 个活跃的告警条件"
            : "\(activeAlertTypes.count) alert conditions are currently active"
    }

    var recentAlertsText: String {
        if recentAlerts.isEmpty {
            return resolvedLanguage == .simplifiedChinese
                ? "当某条规则首次触发时，最近告警会显示在这里"
                : "Recent alerts will appear here when a rule first becomes active"
        }

        if recentAlerts.count == 1 {
            return resolvedLanguage == .simplifiedChinese ? "1 条最近告警" : "1 recent alert"
        }

        return resolvedLanguage == .simplifiedChinese
            ? "\(recentAlerts.count) 条最近告警"
            : "\(recentAlerts.count) recent alerts"
    }

    var cpuCoreCountText: String {
        if cpuCores.isEmpty {
            return resolvedLanguage == .simplifiedChinese ? "正在采集每核心使用率" : "Collecting per-core usage"
        }

        if cpuCores.count == 1 {
            return resolvedLanguage == .simplifiedChinese ? "1 个逻辑核心" : "1 logical core"
        }

        return resolvedLanguage == .simplifiedChinese
            ? "\(cpuCores.count) 个逻辑核心"
            : "\(cpuCores.count) logical cores"
    }

    var cpuCoreTrendValues: [Double] {
        cpuCores.map(\.usage)
    }

    func cpuCoreUsageText(for core: CPUCoreSnapshot) -> String {
        percentageString(from: core.usage)
    }

    var memoryUsageText: String {
        percentageString(from: memoryUsage)
    }

    var memoryFootprintText: String {
        guard memoryTotalBytes > 0 else {
            return resolvedLanguage == .simplifiedChinese ? "正在采集内存使用率" : "Collecting memory usage"
        }

        return "\(storageString(from: memoryUsedBytes)) / \(storageString(from: memoryTotalBytes))"
    }

    var diskUsageText: String {
        guard diskTotalBytes > 0 else {
            return resolvedLanguage == .simplifiedChinese ? "正在采集磁盘使用率" : "Collecting disk usage"
        }

        return percentageString(from: Double(diskUsedBytes) / Double(diskTotalBytes))
    }

    var diskFootprintText: String {
        guard diskTotalBytes > 0 else {
            return resolvedLanguage == .simplifiedChinese ? "采样后会显示磁盘指标" : "Disk metrics will appear once sampled"
        }

        return resolvedLanguage == .simplifiedChinese
            ? "已用 \(storageString(from: diskUsedBytes)) / \(storageString(from: diskTotalBytes))"
            : "\(storageString(from: diskUsedBytes)) / \(storageString(from: diskTotalBytes)) used"
    }

    var diskReadRateText: String {
        rateString(from: diskReadBytesPerSecond)
    }

    var diskWriteRateText: String {
        rateString(from: diskWriteBytesPerSecond)
    }

    var diskActivityText: String {
        resolvedLanguage == .simplifiedChinese
            ? "读取 \(diskReadRateText) • 写入 \(diskWriteRateText)"
            : "Read \(diskReadRateText) • Write \(diskWriteRateText)"
    }

    var combinedDiskRateText: String {
        resolvedLanguage == .simplifiedChinese
            ? "读 \(diskReadRateText) 写 \(diskWriteRateText)"
            : "R \(diskReadRateText) W \(diskWriteRateText)"
    }

    var downloadRateText: String {
        rateString(from: networkDownloadBytesPerSecond)
    }

    var uploadRateText: String {
        rateString(from: networkUploadBytesPerSecond)
    }

    var combinedNetworkRateText: String {
        "↓ \(downloadRateText) ↑ \(uploadRateText)"
    }

    var networkStatusText: String {
        if activeNetworkInterfaces == 0 {
            return resolvedLanguage == .simplifiedChinese ? "没有活动网络接口" : "No active interfaces"
        }

        if activeNetworkInterfaces == 1 {
            return resolvedLanguage == .simplifiedChinese ? "1 个活动网络接口" : "1 active interface"
        }

        return resolvedLanguage == .simplifiedChinese
            ? "\(activeNetworkInterfaces) 个活动网络接口"
            : "\(activeNetworkInterfaces) active interfaces"
    }

    var batteryStatusText: String {
        guard let batterySnapshot else {
            return resolvedLanguage == .simplifiedChinese ? "没有电池指标" : "No battery metrics"
        }

        return percentageString(from: batterySnapshot.level)
    }

    var batteryDetailText: String {
        guard let batterySnapshot else {
            return resolvedLanguage == .simplifiedChinese
                ? "这台 Mac 无法提供电池指标"
                : "Battery metrics are unavailable on this Mac"
        }

        let powerText: String
        if batterySnapshot.isCharging {
            powerText = resolvedLanguage == .simplifiedChinese ? "正在充电" : "Charging"
        } else if batterySnapshot.isOnBatteryPower {
            powerText = resolvedLanguage == .simplifiedChinese ? "使用电池供电" : "On battery power"
        } else {
            powerText = resolvedLanguage == .simplifiedChinese ? "使用交流电供电" : "On AC power"
        }

        guard let minutes = batterySnapshot.timeRemainingMinutes, minutes > 0 else {
            return powerText
        }

        if batterySnapshot.isCharging {
            return resolvedLanguage == .simplifiedChinese
                ? "\(powerText) • 距离充满还有 \(durationString(fromMinutes: minutes))"
                : "\(powerText) • \(durationString(fromMinutes: minutes)) to full"
        }

        if batterySnapshot.isOnBatteryPower {
            return resolvedLanguage == .simplifiedChinese
                ? "\(powerText) • 剩余 \(durationString(fromMinutes: minutes))"
                : "\(powerText) • \(durationString(fromMinutes: minutes)) remaining"
        }

        return powerText
    }

    var thermalConditionText: String {
        sensors.thermalCondition.localizedTitle(language: appLanguage)
    }

    var thermalConditionDetailText: String {
        sensors.thermalCondition.localizedDetailText(language: appLanguage)
    }

    var sensorSourceText: String {
        sensors.source.localizedDescription(language: appLanguage)
    }

    var cpuTemperatureText: String {
        temperatureString(from: sensors.cpuTemperatureCelsius)
    }

    var gpuTemperatureText: String {
        temperatureString(from: sensors.gpuTemperatureCelsius)
    }

    var batteryTemperatureText: String {
        temperatureString(from: sensors.batteryTemperatureCelsius)
    }

    var sensorAvailabilityText: String {
        var unavailableSignals: [String] = []

        if sensors.cpuTemperatureCelsius == nil {
            unavailableSignals.append(text(.cpuTemperature))
        }

        if sensors.gpuTemperatureCelsius == nil {
            unavailableSignals.append(text(.gpuTemperature))
        }

        if sensors.fans.isEmpty {
            unavailableSignals.append(resolvedLanguage == .simplifiedChinese ? "风扇数据" : "fan telemetry")
        }

        guard unavailableSignals.isEmpty == false else {
            return resolvedLanguage == .simplifiedChinese
                ? "实时温度和风扇数据可用。"
                : "Live temperature and fan telemetry are available."
        }

        return resolvedLanguage == .simplifiedChinese
            ? unavailableSignals.joined(separator: "、") + " 当前不可用。"
            : unavailableSignals.joined(separator: ", ") + " currently unavailable."
    }

    var fanStatusText: String {
        if sensors.fans.isEmpty {
            return resolvedLanguage == .simplifiedChinese ? "风扇数据不可用" : "Fan telemetry unavailable"
        }

        if sensors.fans.count == 1 {
            return resolvedLanguage == .simplifiedChinese ? "1 个风扇正在上报" : "1 fan reporting"
        }

        return resolvedLanguage == .simplifiedChinese
            ? "\(sensors.fans.count) 个风扇正在上报"
            : "\(sensors.fans.count) fans reporting"
    }

    func fanSpeedText(for fan: FanSnapshot) -> String {
        "\(fan.currentRPM) RPM"
    }

    func fanRangeText(for fan: FanSnapshot) -> String {
        guard let minimumRPM = fan.minimumRPM,
              let maximumRPM = fan.maximumRPM else {
            return resolvedLanguage == .simplifiedChinese ? "范围不可用" : "Range unavailable"
        }

        return "\(minimumRPM)-\(maximumRPM) RPM"
    }

    var runningAppsText: String {
        if processes.isEmpty {
            return text(.noVisibleApps)
        }

        if processes.count == 1 {
            return resolvedLanguage == .simplifiedChinese ? "1 个可见应用" : "1 visible app"
        }

        return resolvedLanguage == .simplifiedChinese
            ? "\(processes.count) 个可见应用"
            : "\(processes.count) visible apps"
    }

    var historySummaryText: String {
        historySummaryText(for: historySamples)
    }

    var dayHistorySummaryText: String {
        historySummaryText(for: dayHistorySamples)
    }

    var historyStorageSummaryText: String {
        let recentCount = historySamples.count
        let dayCount = dayHistorySamples.count

        if recentCount == 0, dayCount == 0 {
            return resolvedLanguage == .simplifiedChinese
                ? "首次采样成功后会开始积累历史记录"
                : "History populates after the first successful samples"
        }

        return resolvedLanguage == .simplifiedChinese
            ? "\(recentCount) 条实时样本和 \(dayCount) 个分钟桶"
            : "\(recentCount) live samples and \(dayCount) minute buckets"
    }

    var cpuTrendValues: [Double] {
        historySamples.map(\.cpuUsage)
    }

    var memoryTrendValues: [Double] {
        historySamples.map(\.memoryUsage)
    }

    var networkTrendValues: [Double] {
        historySamples.map { Double($0.networkThroughputBytesPerSecond) }
    }

    var diskTrendValues: [Double] {
        historySamples.map { Double($0.diskThroughputBytesPerSecond) }
    }

    var batteryTrendValues: [Double] {
        historySamples.compactMap(\.batteryLevel)
    }

    var lastUpdatedText: String {
        let components = Calendar.current.dateComponents([.hour, .minute], from: lastUpdatedAt)
        let hour = components.hour ?? 0
        let minute = components.minute ?? 0

        return "\(twoDigitString(hour)):\(twoDigitString(minute))"
    }

    var platformArchitectureText: String {
        switch (resolvedLanguage, PlatformCapabilities.current.architecture) {
        case (.system, .appleSilicon):
            return "Apple Silicon"
        case (.system, .intel):
            return "Intel"
        case (.simplifiedChinese, .appleSilicon):
            return "Apple Silicon"
        case (.simplifiedChinese, .intel):
            return "Intel"
        case (.english, .appleSilicon):
            return "Apple Silicon"
        case (.english, .intel):
            return "Intel"
        }
    }

    var compatibilityText: String {
        switch resolvedLanguage {
        case .simplifiedChinese:
            return "macOS 11+ • Intel 与 Apple Silicon"
        case .english, .system:
            return "macOS 11+ • Intel and Apple Silicon"
        }
    }

    func loadPersistedState() async {
        if let storedAppLanguage = await settingsStore.codableValue(
            for: .appLanguage,
            as: AppLanguage.self
        ) {
            appLanguage = storedAppLanguage
        }

        if let storedMenuBarPresentation = await settingsStore.codableValue(
            for: .menuBarPresentation,
            as: MenuBarPresentation.self
        ) {
            menuBarPresentation = storedMenuBarPresentation
        } else if let legacyCompactMenuBarText = await settingsStore.boolValue(for: .compactMenuBarText) {
            menuBarPresentation = MenuBarPresentation(
                textMode: legacyCompactMenuBarText ? .selectedMetric : .appName,
                primaryMetric: .cpuUsage
            )
        } else {
            menuBarPresentation = .default
        }

        if menuBarPresentation.textMode == .selectedMetric,
           menuBarPresentation.primaryMetric == .cpuUsage,
           menuBarPresentation.secondaryMetric == nil,
           menuBarPresentation.tertiaryMetric == nil {
            menuBarPresentation = .default
            let menuBarPresentation = self.menuBarPresentation
            Task {
                await settingsStore.set(menuBarPresentation, for: .menuBarPresentation)
            }
        }

        normalizeMenuBarPresentation()

        if let storedDashboardPresentation = await settingsStore.codableValue(
            for: .dashboardPresentation,
            as: DashboardPresentation.self
        ) {
            dashboardPresentation = storedDashboardPresentation
        } else {
            dashboardPresentation = .default
        }

        if let restoredAlertConfiguration = await settingsStore.codableValue(
            for: .alertConfiguration,
            as: MetricAlertConfiguration.self
        ) {
            alertConfiguration = restoredAlertConfiguration
        }
        let historyTimeline = await historyStore.timeline()
        historySamples = historyTimeline.recentSamples
        dayHistorySamples = historyTimeline.daySamples
        refreshLaunchAtLoginStatus()
    }

    func setMenuBarTextMode(_ value: MenuBarTextMode) {
        updateMenuBarPresentation { presentation in
            presentation.textMode = value.normalized
        }
    }

    func setAppLanguage(_ value: AppLanguage) {
        appLanguage = value

        Task {
            await settingsStore.set(value, for: .appLanguage)
        }
    }

    func setMenuBarPrimaryMetric(_ value: MenuBarPrimaryMetric) {
        updateMenuBarPresentation { presentation in
            var metrics = resolvedMenuBarMetrics(for: presentation)
            metrics.removeAll { $0 == value }
            metrics.insert(value, at: 0)
            assignMenuBarMetrics(metrics, to: &presentation)
        }
    }

    func setDashboardModuleVisible(
        _ module: DashboardModuleType,
        isVisible: Bool
    ) {
        updateDashboardPresentation { presentation in
            let modules = dashboardPresentationModules(from: presentation).map { configuration in
                guard configuration.type == module else {
                    return configuration
                }

                return DashboardModuleConfiguration(
                    type: configuration.type,
                    isVisible: isVisible,
                    isExpandedByDefault: configuration.isExpandedByDefault
                )
            }

            presentation.modules = modules
        }
    }

    func setDashboardModuleExpandedByDefault(
        _ module: DashboardModuleType,
        isExpanded: Bool
    ) {
        updateDashboardPresentation { presentation in
            let modules = dashboardPresentationModules(from: presentation).map { configuration in
                guard configuration.type == module else {
                    return configuration
                }

                return DashboardModuleConfiguration(
                    type: configuration.type,
                    isVisible: configuration.isVisible,
                    isExpandedByDefault: isExpanded
                )
            }

            presentation.modules = modules
        }
    }

    func moveDashboardModuleUp(_ module: DashboardModuleType) {
        updateDashboardPresentation { presentation in
            var modules = dashboardPresentationModules(from: presentation)

            guard let index = modules.firstIndex(where: { $0.type == module }),
                  index > 0 else {
                return
            }

            modules.swapAt(index, index - 1)
            presentation.modules = modules
        }
    }

    func moveDashboardModuleDown(_ module: DashboardModuleType) {
        updateDashboardPresentation { presentation in
            var modules = dashboardPresentationModules(from: presentation)

            guard let index = modules.firstIndex(where: { $0.type == module }),
                  index < modules.count - 1 else {
                return
            }

            modules.swapAt(index, index + 1)
            presentation.modules = modules
        }
    }

    func setMenuBarMetricSelected(
        _ value: MenuBarPrimaryMetric,
        isSelected: Bool
    ) {
        updateMenuBarPresentation { presentation in
            var metrics = resolvedMenuBarMetrics(for: presentation)

            if isSelected {
                guard metrics.contains(value) == false else {
                    return
                }

                metrics.append(value)
            } else {
                guard metrics.count > 1 else {
                    return
                }

                metrics.removeAll { $0 == value }
            }

            assignMenuBarMetrics(metrics, to: &presentation)
        }
    }

    func setCPUAlertEnabled(_ value: Bool) {
        updateAlertConfiguration { configuration in
            configuration.cpuHighUsage.isEnabled = value
        }
    }

    func setCPUAlertThreshold(_ value: Int) {
        updateAlertConfiguration { configuration in
            configuration.cpuHighUsage.thresholdPercent = value
        }
    }

    func setMemoryAlertEnabled(_ value: Bool) {
        updateAlertConfiguration { configuration in
            configuration.memoryHighUsage.isEnabled = value
        }
    }

    func setMemoryAlertThreshold(_ value: Int) {
        updateAlertConfiguration { configuration in
            configuration.memoryHighUsage.thresholdPercent = value
        }
    }

    func setBatteryAlertEnabled(_ value: Bool) {
        updateAlertConfiguration { configuration in
            configuration.batteryLowLevel.isEnabled = value
        }
    }

    func setBatteryAlertThreshold(_ value: Int) {
        updateAlertConfiguration { configuration in
            configuration.batteryLowLevel.thresholdPercent = value
        }
    }

    func setDiskAlertEnabled(_ value: Bool) {
        updateAlertConfiguration { configuration in
            configuration.diskActivityHigh.isEnabled = value
        }
    }

    func setDiskAlertThreshold(_ value: Int) {
        updateAlertConfiguration { configuration in
            configuration.diskActivityHigh.thresholdMegabytesPerSecond = value
        }
    }

    func setAlertCooldownMinutes(_ value: Int) {
        updateAlertConfiguration { configuration in
            configuration.cooldownMinutes = value
        }
    }

    func refreshLaunchAtLoginStatus() {
        launchAtLoginStatus = launchAtLoginService.status()

        if launchAtLoginStatus.requiresApproval == false {
            launchAtLoginErrorMessage = nil
        }
    }

    func setLaunchAtLoginEnabled(_ value: Bool) {
        do {
            launchAtLoginStatus = try launchAtLoginService.setEnabled(value)
            launchAtLoginErrorMessage = nil
        } catch {
            launchAtLoginStatus = launchAtLoginService.status()
            if let launchAtLoginError = error as? LaunchAtLoginError {
                launchAtLoginErrorMessage = launchAtLoginError.description(language: appLanguage)
            } else {
                launchAtLoginErrorMessage = error.localizedDescription
            }
        }
    }

    func updateAlertActivity(
        with alerts: [MetricAlert],
        at timestamp: Date
    ) {
        let nextActiveAlertTypes = Set(alerts.map(\.type))
        let newlyActivatedAlerts = alerts.filter { activeAlertTypes.contains($0.type) == false }
        activeAlertTypes = nextActiveAlertTypes

        guard newlyActivatedAlerts.isEmpty == false else {
            return
        }

        let recentEntries = newlyActivatedAlerts.map { alert in
            RecentAlert(
                type: alert.type,
                title: alert.title,
                body: alert.body,
                timestamp: timestamp
            )
        }

        recentAlerts = Array((recentEntries + recentAlerts).prefix(8))
    }

    func apply(_ snapshot: MetricSnapshot) {
        cpuUsage = snapshot.cpuUsage
        cpuCores = snapshot.cpuCores
        memoryUsage = snapshot.memoryUsage
        memoryUsedBytes = snapshot.memoryUsedBytes
        memoryTotalBytes = snapshot.memoryTotalBytes
        diskUsedBytes = snapshot.disk.usedBytes
        diskFreeBytes = snapshot.disk.freeBytes
        diskTotalBytes = snapshot.disk.totalBytes
        diskReadBytesPerSecond = snapshot.disk.readBytesPerSecond
        diskWriteBytesPerSecond = snapshot.disk.writeBytesPerSecond
        networkDownloadBytesPerSecond = snapshot.networkDownloadBytesPerSecond
        networkUploadBytesPerSecond = snapshot.networkUploadBytesPerSecond
        activeNetworkInterfaces = snapshot.activeNetworkInterfaces
        batterySnapshot = snapshot.battery
        sensors = snapshot.sensors
        processes = snapshot.processes
        platformSummary = snapshot.platform.architecture.rawValue
        lastUpdatedAt = snapshot.timestamp
    }

    func applyHistory(_ timeline: MetricHistoryArchive) {
        historySamples = timeline.recentSamples
        dayHistorySamples = timeline.daySamples
    }

    func setErrorMessage(_ message: String?) {
        errorMessage = message
    }

    private func percentageString(from value: Double) -> String {
        let percentage = Int((value * 100).rounded())
        return "\(percentage)%"
    }

    private func menuBarMetricText(for metric: MenuBarPrimaryMetric) -> String {
        switch metric {
        case .cpuUsage:
            cpuUsageText
        case .memoryUsage:
            memoryUsageText
        case .networkThroughput:
            combinedNetworkRateText
        case .networkDownload:
            downloadRateText
        case .networkUpload:
            uploadRateText
        case .diskActivity:
            rateString(from: diskReadBytesPerSecond + diskWriteBytesPerSecond)
        case .batteryLevel:
            batterySnapshot == nil ? (resolvedLanguage == .simplifiedChinese ? "无" : "n/a") : batteryStatusText
        }
    }

    private func resolvedMenuBarMetrics(
        for presentation: MenuBarPresentation
    ) -> [MenuBarPrimaryMetric] {
        let legacyMetrics = [
            presentation.primaryMetric,
            presentation.secondaryMetric,
            presentation.tertiaryMetric,
        ].compactMap { $0 }
        let metrics = (presentation.selectedMetrics?.isEmpty == false ? presentation.selectedMetrics : legacyMetrics) ?? legacyMetrics

        let uniqueMetrics = metrics.reduce(into: [MenuBarPrimaryMetric]()) { partialResult, metric in
            if partialResult.contains(metric) == false {
                partialResult.append(metric)
            }
        }

        let normalizedMetrics = uniqueMetrics.isEmpty
            ? [presentation.primaryMetric]
            : uniqueMetrics

        return normalizedMetrics
    }

    private func assignMenuBarMetrics(
        _ metrics: [MenuBarPrimaryMetric],
        to presentation: inout MenuBarPresentation
    ) {
        let normalizedMetrics = metrics.isEmpty ? [presentation.primaryMetric] : metrics

        presentation.primaryMetric = normalizedMetrics.first ?? .cpuUsage
        presentation.secondaryMetric = normalizedMetrics.count > 1 ? normalizedMetrics[1] : nil
        presentation.tertiaryMetric = normalizedMetrics.count > 2 ? normalizedMetrics[2] : nil
        presentation.selectedMetrics = normalizedMetrics
    }

    private func localizedMenuBarMetricList(from metrics: [MenuBarPrimaryMetric]) -> String {
        let separator = resolvedLanguage == .simplifiedChinese ? "、" : ", "
        return metrics.map(menuBarPrimaryMetricTitle).joined(separator: separator)
    }

    private func dashboardPresentationModules(
        from presentation: DashboardPresentation
    ) -> [DashboardModuleConfiguration] {
        presentation.orderedModules
    }

    private func normalizeMenuBarPresentation() {
        menuBarPresentation.textMode = menuBarPresentation.textMode.normalized
        let metrics = resolvedMenuBarMetrics(for: menuBarPresentation)
        assignMenuBarMetrics(metrics, to: &menuBarPresentation)
    }

    func historySummaryText(for samples: [MetricHistorySample]) -> String {
        guard let firstSample = samples.first,
              let lastSample = samples.last else {
            return resolvedLanguage == .simplifiedChinese
                ? "首次采样成功后会开始积累历史记录"
                : "History populates after the first successful samples"
        }

        let interval = max(lastSample.timestamp.timeIntervalSince(firstSample.timestamp), 0)

        if interval < 60 {
            return resolvedLanguage == .simplifiedChinese
                ? "\(samples.count) 条样本，跨度 \(Int(interval.rounded())) 秒"
                : "\(samples.count) samples across \(Int(interval.rounded()))s"
        }

        let duration = durationString(fromMinutes: Int((interval / 60).rounded()))
        return resolvedLanguage == .simplifiedChinese
            ? "\(samples.count) 条样本，跨度 \(duration)"
            : "\(samples.count) samples across \(duration)"
    }

    private func updateAlertConfiguration(
        _ update: (inout MetricAlertConfiguration) -> Void
    ) {
        update(&alertConfiguration)
        let alertConfiguration = self.alertConfiguration

        Task {
            await settingsStore.set(alertConfiguration, for: .alertConfiguration)
        }
    }

    private func updateMenuBarPresentation(
        _ update: (inout MenuBarPresentation) -> Void
    ) {
        update(&menuBarPresentation)
        normalizeMenuBarPresentation()
        let menuBarPresentation = self.menuBarPresentation

        Task {
            await settingsStore.set(menuBarPresentation, for: .menuBarPresentation)
        }
    }

    private func updateDashboardPresentation(
        _ update: (inout DashboardPresentation) -> Void
    ) {
        update(&dashboardPresentation)
        dashboardPresentation = DashboardPresentation(modules: dashboardPresentation.modules)
        let dashboardPresentation = self.dashboardPresentation

        Task {
            await settingsStore.set(dashboardPresentation, for: .dashboardPresentation)
        }
    }

    private func decimalString(from value: Double) -> String {
        let roundedValue = (value * 10).rounded() / 10
        let wholePart = Int(roundedValue.rounded(.towardZero))
        let decimalPart = Int(abs((roundedValue - Double(wholePart)) * 10).rounded())

        return "\(wholePart).\(decimalPart)"
    }

    func recentAlertTimestampText(for alert: RecentAlert) -> String {
        let components = Calendar.current.dateComponents([.hour, .minute], from: alert.timestamp)
        let hour = components.hour ?? 0
        let minute = components.minute ?? 0

        return "\(twoDigitString(hour)):\(twoDigitString(minute))"
    }

    private func storageString(from bytes: UInt64) -> String {
        let units = ["B", "KB", "MB", "GB", "TB"]
        var scaledValue = Double(bytes)
        var unitIndex = 0

        while scaledValue >= 1_024 && unitIndex < units.count - 1 {
            scaledValue /= 1_024
            unitIndex += 1
        }

        if unitIndex == 0 {
            return "\(bytes) \(units[unitIndex])"
        }

        return "\(decimalString(from: scaledValue)) \(units[unitIndex])"
    }

    private func durationString(fromMinutes minutes: Int) -> String {
        let hours = minutes / 60
        let remainingMinutes = minutes % 60

        if hours == 0 {
            return resolvedLanguage == .simplifiedChinese ? "\(remainingMinutes) 分钟" : "\(remainingMinutes)m"
        }

        if remainingMinutes == 0 {
            return resolvedLanguage == .simplifiedChinese ? "\(hours) 小时" : "\(hours)h"
        }

        return resolvedLanguage == .simplifiedChinese
            ? "\(hours) 小时 \(remainingMinutes) 分钟"
            : "\(hours)h \(remainingMinutes)m"
    }

    private func rateString(from bytesPerSecond: UInt64) -> String {
        let bytes = Double(bytesPerSecond)

        if bytes >= 1_048_576 {
            return "\(decimalString(from: bytes / 1_048_576)) MB/s"
        }

        if bytes >= 1_024 {
            return "\(decimalString(from: bytes / 1_024)) KB/s"
        }

        return "\(bytesPerSecond) B/s"
    }

    private func temperatureString(from value: Double?) -> String {
        guard let value else {
            return text(.unavailable)
        }

        return "\(decimalString(from: value)) C"
    }

    private func twoDigitString(_ value: Int) -> String {
        if value < 10 {
            return "0\(value)"
        }

        return "\(value)"
    }
}
