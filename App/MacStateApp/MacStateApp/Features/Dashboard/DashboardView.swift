import SwiftUI
import MacStateFoundation
import MacStateUI

enum DashboardLayout {
    static let popoverWidth: CGFloat = 460
    static let popoverHeight: CGFloat = 780
    static let contentPadding: CGFloat = 16
    static let sectionSpacing: CGFloat = 16
    static let overviewGridSpacing: CGFloat = 12
    static let coreGridSpacing: CGFloat = 12
    static let coreCardMinimumWidth: CGFloat = 160
    static let contentWidth: CGFloat = popoverWidth - (contentPadding * 2)
}

struct DashboardView: View {
    @ObservedObject var appState: AppState
    let refreshMetrics: @MainActor () -> Void
    let openHistory: @MainActor () -> Void
    let openSettings: @MainActor () -> Void
    @State private var moduleExpansionState: [DashboardModuleType: Bool] = [:]

    var body: some View {
        ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: DashboardLayout.sectionSpacing) {
                Text(appState.text(.appTitle))
                    .font(.title2)
                    .bold()

                Text(appState.text(.liveMacOSSystemMonitor))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                MetricCard(appState.text(.overview)) {
                    LazyVGrid(
                        columns: [
                            GridItem(.flexible(minimum: 0), spacing: DashboardLayout.overviewGridSpacing),
                            GridItem(.flexible(minimum: 0), spacing: DashboardLayout.overviewGridSpacing),
                        ],
                        alignment: .leading,
                        spacing: DashboardLayout.overviewGridSpacing
                    ) {
                        OverviewMetricTile(
                            appState.text(.cpu),
                            value: appState.cpuUsageText,
                            detail: appState.cpuCoreCountText,
                            trendValues: appState.cpuTrendValues,
                            tint: .orange
                        )

                        OverviewMetricTile(
                            appState.text(.memory),
                            value: appState.memoryUsageText,
                            detail: appState.memoryFootprintText,
                            trendValues: appState.memoryTrendValues,
                            tint: .blue
                        )

                        OverviewMetricTile(
                            appState.text(.network),
                            value: appState.combinedNetworkRateText,
                            detail: appState.networkStatusText,
                            trendValues: appState.networkTrendValues,
                            tint: .green
                        )

                        OverviewMetricTile(
                            appState.text(.disk),
                            value: appState.combinedDiskRateText,
                            detail: appState.diskFootprintText,
                            trendValues: appState.diskTrendValues,
                            tint: .gray
                        )
                    }
                }

                ForEach(appState.visibleDashboardModules, id: \.self) { module in
                    switch module {
                    case .cpu:
                        MetricCard(appState.text(.cpu)) {
                            Text(appState.cpuUsageText)
                                .font(.title2)
                                .bold()

                            Text("\(appState.text(.architecturePrefix)): \(appState.platformArchitectureText)")
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    case .cpuCores:
                        CollapsibleMetricCard(
                            appState.text(.cpuCores),
                            isExpanded: moduleExpansionBinding(for: module),
                            expandAccessibilityLabel: appState.text(.showDetails),
                            collapseAccessibilityLabel: appState.text(.hideDetails)
                        ) {
                            Text(appState.cpuCoreCountText)
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        } details: {
                            VStack(alignment: .leading, spacing: 12) {
                                TrendStrip(values: appState.cpuCoreTrendValues, tint: .orange)

                                LazyVGrid(
                                    columns: [
                                        GridItem(
                                            .adaptive(minimum: DashboardLayout.coreCardMinimumWidth),
                                            alignment: .top
                                        ),
                                    ],
                                    alignment: .leading,
                                    spacing: DashboardLayout.coreGridSpacing
                                ) {
                                    ForEach(appState.cpuCores) { core in
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("\(appState.text(.cpu)) \(core.index + 1)")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                                .lineLimit(1)

                                            Text(appState.cpuCoreUsageText(for: core))
                                                .bold()

                                            ProgressView(value: core.usage)
                                                .frame(maxWidth: .infinity)
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                }
                            }
                        }
                    case .memory:
                        MetricCard(appState.text(.memory)) {
                            Text(appState.memoryUsageText)
                                .font(.title2)
                                .bold()

                            Text(appState.memoryFootprintText)
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    case .disk:
                        MetricCard(appState.text(.disk)) {
                            Text(appState.diskUsageText)
                                .font(.title2)
                                .bold()

                            Text(appState.diskFootprintText)
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)

                            Text(appState.diskActivityText)
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    case .battery:
                        MetricCard(appState.text(.battery)) {
                            Text(appState.batteryStatusText)
                                .font(.title2)
                                .bold()

                            Text(appState.batteryDetailText)
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    case .sensors:
                        CollapsibleMetricCard(
                            appState.text(.sensors),
                            isExpanded: moduleExpansionBinding(for: module),
                            expandAccessibilityLabel: appState.text(.showDetails),
                            collapseAccessibilityLabel: appState.text(.hideDetails)
                        ) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(appState.thermalConditionText)
                                    .font(.title3)
                                    .bold()

                                Text(appState.sensorSourceText)
                                    .foregroundColor(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        } details: {
                            VStack(alignment: .leading, spacing: 12) {
                                Text(appState.thermalConditionDetailText)
                                    .foregroundColor(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)

                                VStack(alignment: .leading, spacing: 8) {
                                    HStack(alignment: .firstTextBaseline) {
                                        Text(appState.text(.cpuLabel))
                                            .font(.caption)
                                            .foregroundColor(.secondary)

                                        Spacer()

                                        Text(appState.cpuTemperatureText)
                                            .bold()
                                    }

                                    HStack(alignment: .firstTextBaseline) {
                                        Text(appState.text(.gpuLabel))
                                            .font(.caption)
                                            .foregroundColor(.secondary)

                                        Spacer()

                                        Text(appState.gpuTemperatureText)
                                            .bold()
                                    }

                                    HStack(alignment: .firstTextBaseline) {
                                        Text(appState.text(.batteryLabel))
                                            .font(.caption)
                                            .foregroundColor(.secondary)

                                        Spacer()

                                        Text(appState.batteryTemperatureText)
                                            .bold()
                                    }
                                }

                                Text(appState.fanStatusText)
                                    .foregroundColor(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)

                                if appState.sensors.fans.isEmpty == false {
                                    VStack(alignment: .leading, spacing: 8) {
                                        ForEach(appState.sensors.fans) { fan in
                                            HStack(alignment: .firstTextBaseline) {
                                                VStack(alignment: .leading, spacing: 4) {
                                                    Text(appState.resolvedLanguage == .simplifiedChinese ? "风扇 \(fan.index + 1)" : "Fan \(fan.index + 1)")
                                                        .font(.caption)
                                                        .foregroundColor(.secondary)

                                                    Text(appState.fanRangeText(for: fan))
                                                        .foregroundColor(.secondary)
                                                }

                                                Spacer()

                                                Text(appState.fanSpeedText(for: fan))
                                                    .bold()
                                            }
                                        }
                                    }
                                }

                                Text(appState.sensorAvailabilityText)
                                    .foregroundColor(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    case .network:
                        MetricCard(appState.text(.network)) {
                            Text(appState.downloadRateText)
                                .font(.title2)
                                .bold()

                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(appState.text(.upload)) \(appState.uploadRateText)")
                                    .foregroundColor(.secondary)

                                Text(appState.networkStatusText)
                                    .foregroundColor(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    case .alerts:
                        CollapsibleMetricCard(
                            appState.text(.alerts),
                            isExpanded: moduleExpansionBinding(for: module),
                            expandAccessibilityLabel: appState.text(.showDetails),
                            collapseAccessibilityLabel: appState.text(.hideDetails)
                        ) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(appState.alertsStatusText)
                                    .font(.headline)
                                    .fixedSize(horizontal: false, vertical: true)

                                Text(appState.alertsSummaryText)
                                    .foregroundColor(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)

                                Text(appState.recentAlertsText)
                                    .foregroundColor(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        } details: {
                            if appState.recentAlerts.isEmpty == false {
                                VStack(alignment: .leading, spacing: 10) {
                                    ForEach(Array(appState.recentAlerts.prefix(4))) { alert in
                                        VStack(alignment: .leading, spacing: 4) {
                                            HStack(alignment: .firstTextBaseline) {
                                                Text(alert.title)
                                                    .bold()
                                                    .lineLimit(2)

                                                Spacer()

                                                Text(appState.recentAlertTimestampText(for: alert))
                                                    .foregroundColor(.secondary)
                                            }

                                            Text(alert.body)
                                                .foregroundColor(.secondary)
                                                .fixedSize(horizontal: false, vertical: true)
                                        }
                                    }
                                }
                            }
                        }
                    case .trends:
                        CollapsibleMetricCard(
                            appState.text(.trends),
                            isExpanded: moduleExpansionBinding(for: module),
                            expandAccessibilityLabel: appState.text(.showDetails),
                            collapseAccessibilityLabel: appState.text(.hideDetails)
                        ) {
                            Text(appState.historySummaryText)
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        } details: {
                            VStack(alignment: .leading, spacing: 12) {
                                Text(appState.text(.cpu))
                                    .font(.subheadline)
                                    .bold()
                                TrendStrip(values: appState.cpuTrendValues, tint: .red)

                                Text(appState.text(.memory))
                                    .font(.subheadline)
                                    .bold()
                                TrendStrip(values: appState.memoryTrendValues, tint: .blue)

                                Text(appState.text(.network))
                                    .font(.subheadline)
                                    .bold()
                                TrendStrip(values: appState.networkTrendValues, tint: .green)

                                Text(appState.text(.battery))
                                    .font(.subheadline)
                                    .bold()
                                TrendStrip(values: appState.batteryTrendValues, tint: .orange)

                                Text(appState.text(.disk))
                                    .font(.subheadline)
                                    .bold()
                                TrendStrip(values: appState.diskTrendValues, tint: .gray)
                            }
                        }
                    case .runningApps:
                        CollapsibleMetricCard(
                            appState.text(.runningApps),
                            isExpanded: moduleExpansionBinding(for: module),
                            expandAccessibilityLabel: appState.text(.showDetails),
                            collapseAccessibilityLabel: appState.text(.hideDetails)
                        ) {
                            Text(appState.runningAppsText)
                                .font(.title3)
                                .bold()
                                .fixedSize(horizontal: false, vertical: true)
                        } details: {
                            if appState.processes.isEmpty {
                                Text(appState.text(.visibleAppsAfterScan))
                                    .foregroundColor(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            } else {
                                VStack(alignment: .leading, spacing: 8) {
                                    ForEach(appState.processes) { process in
                                        HStack(alignment: .firstTextBaseline) {
                                            Text(process.name)
                                                .lineLimit(1)

                                            Spacer()

                                            if process.isFrontmost {
                                                Text(appState.text(.frontmost))
                                                    .foregroundColor(.secondary)
                                            } else {
                                                Text("PID \(process.pid)")
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                Text("\(appState.text(.lastUpdated)) \(appState.lastUpdatedText)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                if let errorMessage = appState.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Button {
                    refreshMetrics()
                } label: {
                    Label(appState.text(.refreshMetrics), systemImage: "arrow.clockwise")
                }

                Button {
                    openHistory()
                } label: {
                    Label(appState.text(.openHistory), systemImage: "chart.xyaxis.line")
                }

                Button {
                    openSettings()
                } label: {
                    Label(appState.text(.openSettings), systemImage: "gearshape")
                }
            }
            .padding(DashboardLayout.contentPadding)
            .frame(width: DashboardLayout.contentWidth, alignment: .leading)
        }
        .frame(width: DashboardLayout.popoverWidth, height: DashboardLayout.popoverHeight)
    }

    private func moduleExpansionBinding(for module: DashboardModuleType) -> Binding<Bool> {
        Binding {
            moduleExpansionState[module] ?? appState.isDashboardModuleExpandedByDefault(module)
        } set: { isExpanded in
            moduleExpansionState[module] = isExpanded
        }
    }
}
