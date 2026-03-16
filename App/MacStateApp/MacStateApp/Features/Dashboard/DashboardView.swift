import SwiftUI
import MacStateUI

struct DashboardView: View {
    @ObservedObject var appState: AppState
    let refreshMetrics: @MainActor () -> Void
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
                }

                MetricCard("Battery") {
                    Text(appState.batteryStatusText)
                        .font(.title2)
                        .bold()

                    Text(appState.batteryDetailText)
                        .foregroundColor(.secondary)
                }

                MetricCard("Network") {
                    Text(appState.downloadRateText)
                        .font(.title2)
                        .bold()

                    Text("Upload \(appState.uploadRateText) • \(appState.networkStatusText)")
                        .foregroundColor(.secondary)
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
                    openSettings()
                } label: {
                    Label("Open Settings", systemImage: "gearshape")
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(width: 400, height: 680)
    }
}
