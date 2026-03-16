import SwiftUI
import MacStateUI

struct DashboardView: View {
    @ObservedObject var appState: AppState
    let refreshMetrics: @MainActor () -> Void
    let openHistory: @MainActor () -> Void
    let openSettings: @MainActor () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("mac-state")
                    .font(.title2)
                    .bold()

                Text("Live macOS system monitor")
                    .foregroundColor(.secondary)

                MetricCard("CPU") {
                    Text(appState.cpuUsageText)
                        .font(.title2)
                        .bold()

                    Text("Architecture: \(appState.platformSummary)")
                        .foregroundColor(.secondary)
                }

                MetricCard("CPU Cores") {
                    Text(appState.cpuCoreCountText)
                        .foregroundColor(.secondary)

                    TrendStrip(values: appState.cpuCoreTrendValues, tint: .orange)

                    LazyVGrid(
                        columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                        ],
                        alignment: .leading,
                        spacing: 8
                    ) {
                        ForEach(appState.cpuCores) { core in
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Core \(core.index + 1)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)

                                Text(appState.cpuCoreUsageText(for: core))
                                    .bold()

                                ProgressView(value: core.usage)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }

                MetricCard("Memory") {
                    Text(appState.memoryUsageText)
                        .font(.title2)
                        .bold()

                    Text(appState.memoryFootprintText)
                        .foregroundColor(.secondary)
                }

                MetricCard("Disk") {
                    Text(appState.diskUsageText)
                        .font(.title2)
                        .bold()

                    Text(appState.diskFootprintText)
                        .foregroundColor(.secondary)

                    Text(appState.diskActivityText)
                        .foregroundColor(.secondary)
                }

                MetricCard("Battery") {
                    Text(appState.batteryStatusText)
                        .font(.title2)
                        .bold()

                    Text(appState.batteryDetailText)
                        .foregroundColor(.secondary)
                }

                MetricCard("Sensors") {
                    Text(appState.thermalConditionText)
                        .font(.title3)
                        .bold()

                    Text(appState.thermalConditionDetailText)
                        .foregroundColor(.secondary)

                    Text(appState.sensorSourceText)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .firstTextBaseline) {
                            Text("CPU")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Spacer()

                            Text(appState.cpuTemperatureText)
                                .bold()
                        }

                        HStack(alignment: .firstTextBaseline) {
                            Text("GPU")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Spacer()

                            Text(appState.gpuTemperatureText)
                                .bold()
                        }

                        HStack(alignment: .firstTextBaseline) {
                            Text("Battery")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Spacer()

                            Text(appState.batteryTemperatureText)
                                .bold()
                        }
                    }

                    Text(appState.fanStatusText)
                        .foregroundColor(.secondary)

                    if appState.sensors.fans.isEmpty == false {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(appState.sensors.fans) { fan in
                                HStack(alignment: .firstTextBaseline) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Fan \(fan.index + 1)")
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

                MetricCard("Network") {
                    Text(appState.downloadRateText)
                        .font(.title2)
                        .bold()

                    Text("Upload \(appState.uploadRateText) • \(appState.networkStatusText)")
                        .foregroundColor(.secondary)
                }

                MetricCard("Alerts") {
                    Text(appState.alertsStatusText)
                        .font(.headline)

                    Text(appState.alertsSummaryText)
                        .foregroundColor(.secondary)

                    Text(appState.recentAlertsText)
                        .foregroundColor(.secondary)

                    if appState.recentAlerts.isEmpty == false {
                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(Array(appState.recentAlerts.prefix(4))) { alert in
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack(alignment: .firstTextBaseline) {
                                        Text(alert.title)
                                            .bold()
                                            .lineLimit(1)

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

                MetricCard("Trends") {
                    Text(appState.historySummaryText)
                        .foregroundColor(.secondary)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("CPU")
                            .font(.subheadline)
                            .bold()
                        TrendStrip(values: appState.cpuTrendValues, tint: .red)

                        Text("Memory")
                            .font(.subheadline)
                            .bold()
                        TrendStrip(values: appState.memoryTrendValues, tint: .blue)

                        Text("Network")
                            .font(.subheadline)
                            .bold()
                        TrendStrip(values: appState.networkTrendValues, tint: .green)

                        Text("Battery")
                            .font(.subheadline)
                            .bold()
                        TrendStrip(values: appState.batteryTrendValues, tint: .orange)

                        Text("Disk")
                            .font(.subheadline)
                            .bold()
                        TrendStrip(values: appState.diskTrendValues, tint: .gray)
                    }
                }

                MetricCard("Running Apps") {
                    Text(appState.runningAppsText)
                        .font(.title3)
                        .bold()

                    if appState.processes.isEmpty {
                        Text("Visible apps will appear after the first process scan.")
                            .foregroundColor(.secondary)
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(appState.processes) { process in
                                HStack(alignment: .firstTextBaseline) {
                                    Text(process.name)
                                        .lineLimit(1)

                                    Spacer()

                                    if process.isFrontmost {
                                        Text("Frontmost")
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

                Text("Last updated \(appState.lastUpdatedText)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                if let errorMessage = appState.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.secondary)
                }

                Button {
                    refreshMetrics()
                } label: {
                    Label("Refresh Metrics", systemImage: "arrow.clockwise")
                }

                Button {
                    openHistory()
                } label: {
                    Label("Open History", systemImage: "chart.xyaxis.line")
                }

                Button {
                    openSettings()
                } label: {
                    Label("Open Settings", systemImage: "gearshape")
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(width: 420, height: 780)
    }
}
